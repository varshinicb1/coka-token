import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/expense.dart';
import '../models/cart_item.dart';
import '../models/bank_statement_item.dart';
import '../data/token_phrases.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/cart_serializer.dart';
import '../utils/receipt_formatter.dart';
import '../services/csv_export_service.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/firestore_service.dart';
import '../services/update_service.dart';
import '../services/pdf_receipt_service.dart';
import '../config/firebase_config.dart';
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

final _log = Logger('AppProvider');

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

class AppProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  final FirestoreService _cloud = FirestoreService();
  final BluetoothPrinterService _btService = BluetoothPrinterService();
  final AuthService _authService = AuthService();
  final UpdateService _updateService = UpdateService();

  // Auth
  User? _currentUser;
  String? _loginError;
  String? _registrationSuccess;
  bool _isFirebaseLoading = false;
  StreamSubscription<firebase_auth.User?>? _authSub;

  // Init
  bool _isInitialized = false;
  bool _initInProgress = false;

  // UI
  String _currentScreen = 'LOGIN';
  bool _isDarkMode = false;
  String _themeStyle = 'coka'; // 'coka' | 'mario'
  bool _bluetoothConnected = false;
  bool _isCloudSynced = false;

  // Mutexes for race condition prevention
  bool _checkoutInProgress = false;
  bool _syncInProgress = false;
  bool _comPortRestoreInProgress = false;
  bool _printInProgress = false;

  // Track order IDs confirmed deleted from cloud to prevent re-sync (Bug 4)
  final Set<int> _confirmedDeletedOrderIds = {};

  // Data
  List<MenuItem> _menuItems = [];
  List<Order> _orders = [];
  List<Expense> _expenses = [];
  List<User> _users = [];

  // Cart
  List<CartItem> _cart = [];
  String _tokenInput = '';
  final TextEditingController tokenController = TextEditingController();
  String _selectedPaymentMethod = 'UPI';
  Order? _activeOrderForReceipt;

  // Search
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Bank Reconciliation
  List<BankStatementItem> _bankStatements = [];
  String _reconciliationLog = 'Reconciliation ledger is empty.';

  // CSV Export
  String _csvExportMessage = '';

  // EOD
  bool _isEodInProgress = false;

  // Update
  UpdateInfo? _pendingUpdate;

  // UPI ID for QR payments
  String _upiId = 'coka@upi';

  // Getters
  bool get isInitialized => _isInitialized;
  User? get currentUser => _currentUser;
  String? get loginError => _loginError;
  String? get registrationSuccess => _registrationSuccess;
  bool get isFirebaseLoading => _isFirebaseLoading;
  String get currentScreen => _currentScreen;
  bool get isDarkMode => _isDarkMode;
  bool get bluetoothConnected => _bluetoothConnected;
  bool get isCloudSynced => _isCloudSynced;
  List<MenuItem> get menuItems => _menuItems;
  List<Order> get orders => _orders;
  List<Expense> get expenses => _expenses;
  List<User> get users => _users;
  List<CartItem> get cart => _cart;
  String get tokenInput => _tokenInput;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  Order? get activeOrderForReceipt => _activeOrderForReceipt;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<BankStatementItem> get bankStatements => _bankStatements;
  String get reconciliationLog => _reconciliationLog;
  BluetoothPrinterService get btService => _btService;
  bool get isFirebaseConfigured => FirebaseConfig.isConfigured;
  String get csvExportMessage => _csvExportMessage;
  bool get isEodInProgress => _isEodInProgress;
  UpdateInfo? get pendingUpdate => _pendingUpdate;
  String get themeStyle => _themeStyle;
  String get upiId => _upiId;
  String get upiMerchantName => 'COKA COIMBATORE ORIGINAL KAALAN ADDA';

  double get todaySales => _orders.where((o) => o.dateString == date_utils.DateUtils.getTodayDateString() && !o.isRefunded).fold(0.0, (s, o) => s + o.totalAmount);
  double get todayExpensesTotal => _expenses.where((e) => e.dateString == date_utils.DateUtils.getTodayDateString()).fold(0.0, (s, e) => s + e.amount);

  List<MenuItem> get filteredMenuItems {
    return _menuItems.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<String> get categories {
    final cats = _menuItems.map((e) => e.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  double get cartSubTotal => _cart.fold(0.0, (sum, item) => sum + item.total);
  double get cartTaxAmount => 0.0;
  double get cartTotal => cartSubTotal;

  // Init
  Future<void> init() async {
    if (_initInProgress) return;
    _initInProgress = true;
    try {
      await _db.prepopulateIfNeeded();
      await _ensureFinalMenuItems();
      await _cloud.init();

      // Check persistent login BEFORE setting up auth listener
      // to avoid race between immediate auth state and delayed listener
      final wasAlreadySignedIn = _authService.isSignedIn;
      final signedInEmail = _authService.currentUser?.email ?? '';

      // Listen to Firebase Auth state for persistent login
      _authSub?.cancel();
      _authSub = _authService.authStateChanges.listen((fUser) async {
        try {
          if (fUser != null && _currentUser == null) {
            await _ensureCloudAfterLogin();
            _autoLoginFromFirebase(fUser.email ?? '');
          } else if (fUser == null && _currentUser != null) {
            _localLogout();
          }
        } catch (e, st) {
          _log.warning('Auth state handler error', e, st);
        }
      });

      await refreshData();
      await _resetTokenInputToNextAuto();

      // Handle persistent session if already signed in
      if (wasAlreadySignedIn && signedInEmail.isNotEmpty && _currentUser == null) {
        await _ensureCloudAfterLogin();
        _autoLoginFromFirebase(signedInEmail);
      }

      // Check for app updates
      _checkForUpdate();

      // Auto-detect and connect to Seiznik Veer printer (Windows)
      if (Platform.isWindows) {
        await _restoreComPort();
      }
    } catch (e, st) {
      _log.severe('Init failed', e, st);
    } finally {
      _isInitialized = true;
      _initInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _ensureFinalMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    const menuVersion = 2;
    final currentVersion = prefs.getInt('menu_version') ?? 0;
    if (currentVersion >= menuVersion) return;

    await _db.ensureFinalMenuItems();
    await _syncMenuStockToCloud();
    await prefs.setInt('menu_version', menuVersion);
    _log.info('Migrated menu to version $menuVersion');
  }

  Future<void> _ensureCloudAfterLogin() async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      final connected = await _cloud.init(force: true);
      if (connected) {
        await _syncAllFromCloud();
        _cloud.listenOrders(_onCloudOrdersChanged);
        _cloud.listenMenuItems(_onCloudMenuChanged); // Bug 2
        _cloud.listenExpenses(_onCloudExpensesChanged); // Bug 9
      }
    } catch (e, st) {
      _log.warning('Cloud init after login failed', e, st);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _autoLoginFromFirebase(String email) async {
    if (_currentUser != null) return;
    try {
      final localUser = await _db.getUser(email);
      if (localUser != null) {
        _currentUser = localUser;
        _currentScreen = 'BILLING';
      } else {
        final newUser = User(username: email, passwordHash: '', role: 'STAFF');
        await _db.insertUser(newUser);
        _currentUser = newUser;
        _currentScreen = 'BILLING';
        _users = await _db.getUsers();
      }
      notifyListeners();
    } catch (e, st) {
      _log.warning('Auto login failed', e, st);
    }
  }

  void _localLogout() {
    _currentUser = null;
    _currentScreen = 'LOGIN';
    _cart = [];
    _activeOrderForReceipt = null;
    notifyListeners();
  }

  Future<void> _syncAllFromCloud() async {
    if (!_cloud.isAvailable) {
      _isCloudSynced = false;
      notifyListeners();
      return;
    }

    try {
      final cloudOrders = await _cloud.loadOrders();
      if (cloudOrders != null && cloudOrders.isNotEmpty) {
        int added = 0;
        for (final m in cloudOrders) {
          final id = m['id'] as int?;
          if (id == null) continue;
          // Skip orders confirmed deleted from cloud (Bug 4)
          if (_confirmedDeletedOrderIds.contains(id)) continue;
          final existingIdx = _orders.indexWhere((o) => o.id == id);
          if (existingIdx == -1) {
            _orders.add(Order.fromMap(m));
            added++;
          } else {
            _orders[existingIdx] = Order.fromMap(m);
          }
        }
        if (added > 0) {
          _orders.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
          await _db.clearAndInsertOrders(_orders);
        }
        _log.info('Synced $added new orders from cloud');
      }
    } catch (e, st) {
      _log.warning('Cloud order sync failed', e, st);
    }

    try {
      final cloudItems = await _cloud.loadMenuItems();
      if (cloudItems != null && cloudItems.isNotEmpty) {
        final localById = {for (final item in _menuItems) if (item.id != null) item.id: item};
        for (final m in cloudItems) {
          final cloudItem = MenuItem.fromMap(m);
          final localItem = cloudItem.id != null ? localById[cloudItem.id] : null;
          if (localItem != null) {
            // Merge: keep local usedStock/remainingStock, update rest from cloud (Bug 1)
            final merged = cloudItem.copyWith(
              usedStock: localItem.usedStock,
              remainingStock: localItem.remainingStock,
            );
            await _db.updateMenuItem(merged);
          } else {
            // New item from cloud, add locally
            await _db.insertMenuItem(cloudItem);
          }
        }
        _menuItems = await _db.getMenuItems();
        _log.info('Merged ${cloudItems.length} menu items from cloud');
      }
    } catch (e, st) {
      _log.warning('Cloud menu sync failed', e, st);
    }

    try {
      final cloudExpenses = await _cloud.loadExpenses();
      if (cloudExpenses != null && cloudExpenses.isNotEmpty) {
        final localById = {for (final e in _expenses) if (e.id != null) e.id: e};
        int added = 0;
        for (final m in cloudExpenses) {
          final expense = Expense.fromMap(m);
          final localExpense = expense.id != null ? localById[expense.id] : null;
          if (localExpense == null) {
            await _db.insertExpense(expense);
            added++;
          }
        }
        if (added > 0) {
          _expenses = await _db.getExpenses();
        }
        _log.info('Merged $added new expenses from cloud');
      }
    } catch (e, st) {
      _log.warning('Cloud expense sync failed', e, st);
    }

    try {
      final cloudUsers = await _cloud.loadUsers();
      if (cloudUsers != null && cloudUsers.isNotEmpty) {
        _users = cloudUsers.map((m) => User.fromMap(m)).toList();
        _log.info('Synced ${_users.length} users from cloud');
      }
    } catch (e, st) {
      _log.warning('Cloud user sync failed', e, st);
    }

    _isCloudSynced = true;
  }

  /// Public method to manually trigger cloud sync
  Future<void> syncWithCloud() async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      final connected = await _cloud.init(force: true);
      if (connected) {
        await _syncAllFromCloud();
        _log.info('Manual cloud sync completed');
      } else {
        _log.warning('Manual cloud sync failed: not connected');
      }
    } catch (e, st) {
      _log.warning('Manual cloud sync failed', e, st);
    } finally {
      _syncInProgress = false;
      notifyListeners();
    }
  }

  void _onCloudOrdersChanged(List<Order> incoming) {
    try {
      final ordersCopy = List<Order>.from(_orders);
      bool changed = false;
      for (final newOrder in incoming) {
        final existingIdx = ordersCopy.indexWhere((o) => o.id == newOrder.id);
        if (existingIdx != -1) {
          ordersCopy[existingIdx] = newOrder;
          changed = true; // Bug 10: notify on updates too
        } else {
          ordersCopy.add(newOrder);
          changed = true;
        }
      }
      if (changed) {
        ordersCopy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _orders = ordersCopy;
        notifyListeners();
      }
    } catch (e, st) {
      _log.warning('Cloud order update failed', e, st);
    }
  }

  void _onCloudMenuChanged(List<MenuItem> incoming) {
    try {
      final localById = {for (final item in _menuItems) if (item.id != null) item.id: item};
      bool changed = false;
      for (final cloudItem in incoming) {
        if (cloudItem.id == null) continue;
        final localItem = localById[cloudItem.id];
        if (localItem != null) {
          // Merge: keep local stock, update rest from cloud (Bug 1)
          final idx = _menuItems.indexWhere((i) => i.id == cloudItem.id);
          if (idx != -1) {
            final merged = cloudItem.copyWith(
              usedStock: localItem.usedStock,
              remainingStock: localItem.remainingStock,
            );
            _menuItems[idx] = merged;
            _db.updateMenuItem(merged);
            changed = true;
          }
        } else {
          // New item from another device, add locally
          _menuItems.add(cloudItem);
          _db.insertMenuItem(cloudItem);
          changed = true;
        }
      }
      if (changed) {
        _menuItems.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e, st) {
      _log.warning('Cloud menu update failed', e, st);
    }
  }

  void _onCloudExpensesChanged(List<Expense> incoming) {
    try {
      final localById = {for (final e in _expenses) if (e.id != null) e.id: e};
      bool changed = false;
      for (final newExpense in incoming) {
        if (newExpense.id == null || !localById.containsKey(newExpense.id)) {
          _expenses.add(newExpense);
          _db.insertExpense(newExpense);
          changed = true;
        }
      }
      if (changed) {
        _expenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e, st) {
      _log.warning('Cloud expense update failed', e, st);
    }
  }

  Future<void> refreshData() async {
    _menuItems = await _db.getMenuItems();
    _orders = await _db.getOrders();
    _expenses = await _db.getExpenses();
    _users = await _db.getUsers();
    notifyListeners();
  }

  // Theme
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setThemeStyle(String style) {
    _themeStyle = style;
    notifyListeners();
  }

  void setUpiId(String id) {
    _upiId = id;
    notifyListeners();
  }

  Future<void> _checkForUpdate() async {
    try {
      _pendingUpdate = await _updateService.check();
      if (_pendingUpdate != null) notifyListeners();
    } catch (_) {}
  }

  void clearPendingUpdate() {
    _pendingUpdate = null;
    notifyListeners();
  }

  // Navigation
  void navigateTo(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  // Auth
  Future<void> loginWithFirebaseOrLocal(String email, String password) async {
    _isFirebaseLoading = true;
    _loginError = null;
    _registrationSuccess = null;
    notifyListeners();

    try {
      // Try Firebase Auth first
      if (FirebaseConfig.isConfigured) {
        final firebaseUser = await _authService.signInWithEmailAndPassword(email, password);
        if (firebaseUser != null) {
          if (_currentUser == null) {
            await _ensureCloudAfterLogin();
            // Firebase auth succeeded — load or create local user record
            if (_currentUser == null) {
              final localUser = await _db.getUser(email);
              if (localUser != null) {
                _currentUser = localUser;
              } else {
                final newUser = User(username: email, passwordHash: _hashPassword(password), role: 'ADMIN');
                await _db.insertUser(newUser);
                _currentUser = newUser;
                _users = await _db.getUsers();
              }
            }
          }
          _loginError = null;
          _currentScreen = 'BILLING';
          _isFirebaseLoading = false;
          notifyListeners();
          return;
        }
        // Firebase failed — fall through to local
        _log.fine('Firebase login failed, falling back to local auth');
      }

      // Local fallback
      final localUser = await _db.getUser(email);
      if (localUser != null && localUser.passwordHash == _hashPassword(password)) {
        _currentUser = localUser;
        _loginError = null;
        _currentScreen = 'BILLING';
      } else {
        _loginError = 'Invalid credentials or user not registered!';
      }
    } catch (e) {
      _loginError = 'Authentication Failed: $e';
    }

    _isFirebaseLoading = false;
    notifyListeners();
  }

  Future<void> registerWithFirebaseOrLocal(String email, String password) async {
    _isFirebaseLoading = true;
    _loginError = null;
    _registrationSuccess = null;
    notifyListeners();

    try {
      if (FirebaseConfig.isConfigured) {
        final firebaseUser = await _authService.createUserWithEmailAndPassword(email, password);
        if (firebaseUser == null) {
          _loginError = 'Registration failed. Try a different email or check your connection.';
          _isFirebaseLoading = false;
          notifyListeners();
          return;
        }
        await _ensureCloudAfterLogin();
      }

      final existing = await _db.getUser(email);
      if (existing != null) {
        _loginError = 'User already exists!';
      } else {
        final newUser = User(username: email, passwordHash: _hashPassword(password), role: 'ADMIN');
        await _db.insertUser(newUser);
        unawaited(_cloud.saveUser(newUser.toMap()));
        _currentUser = newUser;
        _registrationSuccess = 'User registered successfully!';
        _currentScreen = 'BILLING';
        _users = await _db.getUsers();
      }
    } catch (e) {
      _loginError = 'Registration Failed: $e';
    }

    _isFirebaseLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    if (FirebaseConfig.isConfigured) {
      await _authService.signOut();
    }
    _currentUser = null;
    _currentScreen = 'LOGIN';
    _cart = [];
    _activeOrderForReceipt = null;
    notifyListeners();
  }

  // Cart
  void addToCart(MenuItem item, {int quantity = 1}) {
    final idx = _cart.indexWhere((e) => e.name == item.name);
    if (idx != -1) {
      final existing = _cart[idx];
      _cart[idx] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _cart.add(CartItem(itemId: item.id, name: item.name, rate: item.rate, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    final idx = _cart.indexWhere((e) => e.name == item.name);
    if (idx != -1) {
      final existing = _cart[idx];
      if (existing.quantity > 1) {
        _cart[idx] = existing.copyWith(quantity: existing.quantity - 1);
      } else {
        _cart.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _cart = [];
    notifyListeners();
  }

  void setTokenInput(String value) {
    _tokenInput = value;
    tokenController.text = value;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<void> _resetTokenInputToNextAuto() async {
    final today = date_utils.DateUtils.getTodayDateString();
    final todayOrders = _orders.where((o) => o.dateString == today).toList();
    int nextToken = 1;
    if (todayOrders.isNotEmpty) {
      final maxToken = todayOrders
          .map((o) => int.tryParse(o.tokenNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .reduce((a, b) => a > b ? a : b);
      nextToken = maxToken + 1;
    }
    _tokenInput = nextToken.toString();
    tokenController.text = _tokenInput;
    notifyListeners();
  }

  Future<void> checkout({String? paymentMethodOverride, String? gatewayTxnId, String? gatewayStatus = 'SUCCESS', bool autoPrint = false}) async {
    if (_checkoutInProgress) return;
    if (_cart.isEmpty) return;
    if (_cart.any((item) => item.quantity <= 0)) return;

    _checkoutInProgress = true;
    try {
      final enteredToken = _tokenInput.trim().isEmpty ? '1' : _tokenInput.trim();
      final tokenNum = int.tryParse(enteredToken.replaceAll(RegExp(r'[^0-9]'), ''));
      if (tokenNum == null || tokenNum < 1) return;
      final finalPayment = paymentMethodOverride ?? _selectedPaymentMethod;
      final finalTxnId = gatewayTxnId ?? switch (finalPayment) {
        'UPI' => 'UTR420${DateTime.now().millisecondsSinceEpoch % 1000000000}',
        'Card' => 'RRN580${DateTime.now().millisecondsSinceEpoch % 1000000000}',
        _ => 'CASH${DateTime.now().millisecondsSinceEpoch % 1000000}',
      };

      final tokenSlot = ((tokenNum - 1) % 120) + 1;
      final tokenPhrase = TokenPhrases.list[tokenSlot - 1];

      final cartSnapshot = List<CartItem>.from(_cart);
      final order = Order(
        tokenNumber: enteredToken,
        itemsText: CartSerializer.serialize(cartSnapshot),
        subTotal: cartSnapshot.fold(0.0, (sum, item) => sum + item.total),
        taxAmount: 0.0,
        totalAmount: cartSnapshot.fold(0.0, (sum, item) => sum + item.total),
        paymentMethod: finalPayment,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        dateString: date_utils.DateUtils.getTodayDateString(),
        operatorName: _currentUser?.username ?? 'Staff',
        gatewayTransactionId: finalTxnId,
        gatewayStatus: gatewayStatus,
        tokenSlot: tokenSlot,
        tokenPhrase: tokenPhrase,
      );

      final orderId = await _db.insertOrder(order);
      final savedOrder = order.copyWith(id: orderId);
      await _deductStockForOrder(order.itemsText);
      await _cloud.saveOrderWithStockTransaction(savedOrder, cartSnapshot);
      await refreshData();
      await _resetTokenInputToNextAuto();

      _activeOrderForReceipt = savedOrder;
      _cart = [];

      if (autoPrint && _btService.isConnected) {
        await printOrderReceipt(savedOrder);
      }

      notifyListeners();
    } catch (e, st) {
      _log.warning('Checkout failed', e, st);
    } finally {
      _checkoutInProgress = false;
    }
  }

  void clearActiveReceipt() {
    _activeOrderForReceipt = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Order Management
  Future<void> refundOrder(Order order) async {
    final updated = order.copyWith(isRefunded: true);
    await _db.updateOrder(updated);
    unawaited(_cloud.saveOrder(updated.toMap()));
    await refreshData();
    if (_activeOrderForReceipt?.id == order.id) {
      _activeOrderForReceipt = updated;
    }
    notifyListeners();
  }

  Future<void> deleteOrder(Order order) async {
    if (order.id == null) return;
    final id = order.id!;
    await _db.deleteOrder(id);
    final ok = await _cloud.deleteOrder(id);
    if (!ok) {
      _confirmedDeletedOrderIds.add(id);
      _log.warning('Cloud delete failed for order $id, added to local exclusion set');
    }
    await refreshData();
    notifyListeners();
  }

  Future<bool> sharePdfReceipt(Order order) async {
    return await PdfReceiptService.sharePdf(order);
  }

  // Menu Management
  Future<void> saveMenuItem({int? id, required String name, required double rate, required String category, required int openingStock, String description = ''}) async {
    if (id != null && id > 0) {
      final existing = await _db.getMenuItemById(id);
      if (existing != null) {
        final stockDiff = openingStock - existing.openingStock;
        final newRemaining = (existing.remainingStock + stockDiff).clamp(0, openingStock);
        final updated = existing.copyWith(
          name: name,
          rate: rate,
          category: category,
          openingStock: openingStock,
          remainingStock: newRemaining,
          description: description,
        );
        await _db.updateMenuItem(updated);
        if (updated.id != null) unawaited(_cloud.saveMenuItem(updated.toMap()));
      }
    } else {
      final item = MenuItem(
        name: name,
        rate: rate,
        category: category,
        openingStock: openingStock,
        remainingStock: openingStock,
        description: description,
      );
      final newId = await _db.insertMenuItem(item);
      await refreshData();
      unawaited(_cloud.saveMenuItem(item.copyWith(id: newId).toMap()));
      return;
    }
    await refreshData();
  }

  Future<void> deleteMenuItem(MenuItem item) async {
    await _db.deleteMenuItem(item);
    if (item.id != null) unawaited(_cloud.deleteMenuItem(item.id!));
    await refreshData();
  }

  Future<void> quickRestock(MenuItem item) async {
    final updated = item.copyWith(usedStock: 0, remainingStock: item.openingStock);
    await _db.updateMenuItem(updated);
    if (updated.id != null) unawaited(_cloud.saveMenuItem(updated.toMap())); // Bug 5
    await refreshData();
  }

  // Expenses
  Future<void> addExpense(String description, double amount) async {
    final expense = Expense(
      description: description,
      amount: amount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      dateString: date_utils.DateUtils.getTodayDateString(),
    );
    final newId = await _db.insertExpense(expense);
    await refreshData();
    unawaited(_cloud.saveExpense(expense.copyWith(id: newId).toMap()));
  }

  Future<void> deleteExpense(Expense expense) async {
    await _db.deleteExpense(expense);
    if (expense.id != null) unawaited(_cloud.deleteExpense(expense.id!));
    await refreshData();
  }

  // User Management
  Future<void> createUser(User user) async {
    await _db.insertUser(user);
    await refreshData();
    unawaited(_cloud.saveUser(user.toMap())); // Bug 6
  }

  Future<void> removeUser(User user) async {
    if (user.username == _currentUser?.username || user.username == 'admin') return;
    await _db.deleteUser(user);
    await refreshData();
    unawaited(_cloud.deleteUser(user.username)); // Bug 7
  }

  // CSV Export
  Future<String> exportSalesCSV() async {
    final result = await CsvExportService.exportOrders(_orders);
    _csvExportMessage = result;
    notifyListeners();
    return result;
  }

  // EOD
  Future<void> endOfDayReset() async {
    _tokenInput = '1';
    tokenController.text = '1';
    notifyListeners();
  }

  // Bluetooth
  void setBluetoothConnected(bool value) {
    _bluetoothConnected = value;
    notifyListeners();
  }

  // Bank Reconciliation
  void autoMatchReconciliation() {
    int reconciledCount = 0;
    int mismatchCount = 0;

    final updatedStmts = _bankStatements.map((stmt) {
      if (stmt.isMatched) return stmt;

      final exactMatch = _orders.cast<Order?>().firstWhere(
        (o) => o!.gatewayTransactionId == stmt.statementId && !o.isRefunded,
        orElse: () => null,
      );

      if (exactMatch != null) {
        if (exactMatch.totalAmount == stmt.amount) {
          reconciledCount++;
          return stmt.copyWith(isMatched: true, matchedOrderId: exactMatch.id, confidence: 'HIGH');
        } else {
          mismatchCount++;
          return stmt.copyWith(matchedOrderId: exactMatch.id, confidence: 'CONFLICT');
        }
      }

      // Soft match
      final softMatch = _orders.cast<Order?>().firstWhere(
        (o) =>
            !o!.reconciled && !o.isRefunded &&
            o.totalAmount == stmt.amount &&
            o.paymentMethod == stmt.paymentType &&
            o.dateString == stmt.dateString,
        orElse: () => null,
      );

      if (softMatch != null) {
        reconciledCount++;
        return stmt.copyWith(isMatched: true, matchedOrderId: softMatch.id, confidence: 'MEDIUM');
      }

      return stmt;
    }).toList();

    _bankStatements = updatedStmts;
    _reconciliationLog = 'Audit Complete!\n- Reconciled: $reconciledCount\n- Conflicts: $mismatchCount';
    notifyListeners();
  }

  void manualMatchOrder(int orderId, String statementId) {
    final updatedStmts = _bankStatements.map((s) {
      if (s.statementId == statementId) {
        return s.copyWith(isMatched: true, matchedOrderId: orderId, confidence: 'HIGH');
      }
      return s;
    }).toList();
    _bankStatements = updatedStmts;
    _reconciliationLog = 'Manually linked Order #$orderId to $statementId.';
    notifyListeners();
  }

  void resetReconciliation() {
    _bankStatements = [];
    _reconciliationLog = 'Ledger cleared.';
    notifyListeners();
  }

  // ====== BLUETOOTH / USB METHODS ======
  Future<bool> connectBluetooth() async {
    return await _btService.startDiscovery();
  }

  Future<void> connectUsb(String portName) async {
    final ok = await _btService.connectUsb(portName);
    if (ok) {
      _bluetoothConnected = true;
      await _saveComPort(portName);
      notifyListeners();
    }
  }

  void disconnectBluetooth() {
    _btService.disconnect();
    _bluetoothConnected = false;
    _clearComPort();
    notifyListeners();
  }

  Future<void> _restoreComPort() async {
    if (_comPortRestoreInProgress) return;
    _comPortRestoreInProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPort = prefs.getString('com_port');

      if (savedPort != null && savedPort.isNotEmpty) {
        final ok = await _btService.connectUsb(savedPort);
        if (ok) {
          _log.info('Reconnected to saved COM port $savedPort');
          _bluetoothConnected = true;
          notifyListeners();
          return;
        }
      }

      final port = await _btService.findVeerPort();
      if (port != null) {
        final ok = await _btService.connectUsb(port);
        if (ok) {
          _log.info('Auto-connected to printer on $port');
          _bluetoothConnected = true;
          await _saveComPort(port);
          notifyListeners();
        }
      }
    } catch (_) {
      _log.fine('COM port restore failed');
    } finally {
      _comPortRestoreInProgress = false;
    }
  }

  Future<void> _saveComPort(String port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('com_port', port);
    } catch (_) {}
  }

  Future<void> _clearComPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('com_port');
    } catch (_) {}
  }

  Future<bool> printOrderReceipt(Order order) async {
    if (_printInProgress) return false;
    _printInProgress = true;
    try {
      final lines = _generateReceiptLines(order);
      final success = await _btService.printReceipt(lines);
      if (success) {
        _bluetoothConnected = true;
        notifyListeners();
        return true;
      }
      // Printer failed/not connected → auto-generate PDF fallback
      _log.info('Printer unavailable, generating PDF receipt for order ${order.id}');
      return await sharePdfReceipt(order);
    } catch (e) {
      _log.warning('Print receipt failed, falling back to PDF', e);
      return await sharePdfReceipt(order);
    } finally {
      _printInProgress = false;
    }
  }

  Future<bool> printKot(Order order) async {
    if (_printInProgress) return false;
    _printInProgress = true;
    try {
      final lines = _generateKotLines(order);
      final success = await _btService.printReceipt(lines);
      if (success) {
        _bluetoothConnected = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _log.warning('Print KOT failed', e);
      return false;
    } finally {
      _printInProgress = false;
    }
  }

  Future<void> _deductStockForOrder(String itemsText) async {
    if (itemsText.isEmpty) return;
    final itemsData = itemsText.split('|');
    final menuSnapshot = List<MenuItem>.from(_menuItems);
    for (final raw in itemsData) {
      final parts = raw.split('*');
      if (parts.length < 2) continue;
      final name = parts[0];
      final qty = int.tryParse(parts[1]) ?? 0;
      final itemId = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (qty <= 0) continue;

      final match = menuSnapshot.cast<MenuItem?>().firstWhere(
        (i) => itemId != null && i!.id == itemId,
        orElse: () => menuSnapshot.cast<MenuItem?>().firstWhere(
          (i) => i!.name.toLowerCase().trim() == name.toLowerCase().trim(),
          orElse: () => null,
        ),
      );
      if (match != null) {
        final newUsed = match.usedStock + qty;
        final newRemaining = (match.openingStock - newUsed).clamp(0, match.openingStock);
        await _db.updateMenuItem(match.copyWith(usedStock: newUsed, remainingStock: newRemaining));
      }
    }
  }

  Future<void> _syncMenuStockToCloud() async {
    for (final item in _menuItems) {
      if (item.id != null) {
        unawaited(_cloud.saveMenuItem(item.toMap()));
      }
    }
  }

  List<String> _generateReceiptLines(Order order) =>
      ReceiptFormatter.generateReceiptLines(order);

  List<String> _generateKotLines(Order order) =>
      ReceiptFormatter.generateKotLines(order);



  // ====== EOD METHODS ======
  Map<String, dynamic> getEodSummary() {
    final today = date_utils.DateUtils.getTodayDateString();
    final todayOrders = _orders.where((o) => o.dateString == today).toList();
    final todayRefunded = todayOrders.where((o) => o.isRefunded).toList();
    final todayValid = todayOrders.where((o) => !o.isRefunded).toList();
    final todayExpensesTotal = _expenses.where((e) => e.dateString == today).fold(0.0, (s, e) => s + e.amount);

    return {
      'date': today,
      'totalSales': todayValid.fold(0.0, (s, o) => s + o.totalAmount),
      'totalExpenses': todayExpensesTotal,
      'netProfit': todayValid.fold(0.0, (s, o) => s + o.totalAmount) - todayExpensesTotal,
      'orderCount': todayValid.length,
      'refundCount': todayRefunded.length,
      'refundAmount': todayRefunded.fold(0.0, (s, o) => s + o.totalAmount),
      'cashTotal': todayValid.where((o) => o.paymentMethod == 'Cash').fold(0.0, (s, o) => s + o.totalAmount),
      'upiTotal': todayValid.where((o) => o.paymentMethod == 'UPI').fold(0.0, (s, o) => s + o.totalAmount),
      'cardTotal': todayValid.where((o) => o.paymentMethod == 'Card').fold(0.0, (s, o) => s + o.totalAmount),
      'operatorCount': todayValid.map((o) => o.operatorName).toSet().length,
    };
  }

  Future<void> executeEndOfDay() async {
    _isEodInProgress = true;
    notifyListeners();
    _tokenInput = '1';
    tokenController.text = '1';
    await refreshData();
    _isEodInProgress = false;
    notifyListeners();
  }

  List<Order> getOrdersInRange(DateTime start, DateTime end) {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch + Duration.millisecondsPerDay;
    return _orders.where((o) => o.timestamp >= startMs && o.timestamp <= endMs && !o.isRefunded).toList();
  }

  List<Map<String, dynamic>> getDailySalesBreakdown(int days) {
    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final ds = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayOrders = _orders.where((o) => o.dateString == ds && !o.isRefunded).toList();
      result.add({
        'date': ds,
        'total': dayOrders.fold(0.0, (s, o) => s + o.totalAmount),
        'count': dayOrders.length,
      });
    }
    return result;
  }

  // ====== CSV IMPORT FOR BANK RECONCILIATION ======
  Future<void> importBankStatementCsv(String content) async {
    try {
      final csv = const CsvDecoder().convert(content);

      final statements = <BankStatementItem>[];
      for (int i = 1; i < csv.length; i++) {
        final row = csv[i];
        if (row.length < 4) continue;
        final id = row[0].toString().trim();
        final date = row[1].toString().trim();
        final desc = row[2].toString().trim();
        final amt = double.tryParse(row[3].toString().trim()) ?? 0.0;
        final type = row.length > 4 ? row[4].toString().trim() : 'UPI';
        if (id.isEmpty || amt == 0.0) continue;
        statements.add(BankStatementItem(
          statementId: id,
          dateString: date,
          description: desc,
          amount: amt,
          paymentType: type,
        ));
      }

      if (statements.isNotEmpty) {
        _bankStatements = statements;
        _reconciliationLog = 'Imported ${statements.length} records from CSV.';
      } else {
        _reconciliationLog = 'No valid records found in CSV.';
      }
      notifyListeners();
    } catch (e, st) {
      _log.warning('CSV import failed', e, st);
      _reconciliationLog = 'Failed to import CSV: $e';
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getBestSellers({int limit = 5, String? period}) {
    final orders = _orders.where((o) => !o.isRefunded && (period == null || o.dateString == period)).toList();
    final Map<String, int> itemQty = {};
    final Map<String, double> itemRevenue = {};

    for (final order in orders) {
      final items = CartSerializer.deserialize(order.itemsText);
      for (final item in items) {
        itemQty.update(item.name, (v) => v + item.quantity, ifAbsent: () => item.quantity);
        itemRevenue.update(item.name, (v) => v + item.total, ifAbsent: () => item.total);
      }
    }

    final sorted = itemQty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => <String, dynamic>{
      'name': e.key,
      'quantity': e.value,
      'revenue': itemRevenue[e.key] ?? 0.0,
    }).toList();
  }

  List<Map<String, dynamic>> getLowStockItems() {
    return _menuItems
      .where((item) => item.remainingStock > 0 && item.remainingStock <= 5)
      .map((item) => <String, dynamic>{
        'name': item.name,
        'remaining': item.remainingStock,
        'opening': item.openingStock,
      })
      .toList();
  }

  int get todayOrderCount => _orders.where((o) => o.dateString == date_utils.DateUtils.getTodayDateString() && !o.isRefunded).length;

  @override
  void dispose() {
    _authSub?.cancel();
    _authSub = null;
    tokenController.dispose();
    _cloud.dispose();
    super.dispose();
  }
}
