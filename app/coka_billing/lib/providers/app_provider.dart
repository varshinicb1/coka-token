import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../database/app_database.dart';
import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/expense.dart';
import '../models/cart_item.dart';
import '../models/bank_statement_item.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/cart_serializer.dart';
import '../services/csv_export_service.dart';
import '../services/bluetooth_printer_service.dart';
import '../config/firebase_config.dart';
import '../services/firebase_auth_service.dart';


String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

class AppProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  final BluetoothPrinterService _btService = BluetoothPrinterService();

  // Auth
  User? _currentUser;
  String? _loginError;
  String? _registrationSuccess;
  bool _isFirebaseLoading = false;

  // Init
  bool _isInitialized = false;

  // UI
  String _currentScreen = 'LOGIN';
  bool _isDarkMode = false;
  bool _bluetoothConnected = false;
  final bool _isCloudSynced = true;

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
  double get cartTaxAmount => cartSubTotal * 0.05;
  double get cartTotal => cartSubTotal + cartTaxAmount;

  // Init
  Future<void> init() async {
    await _db.prepopulateIfNeeded();
    await refreshData();
    await _resetTokenInputToNextAuto();
    _isInitialized = true;
    notifyListeners();
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
      // Try Firebase first if configured
      if (FirebaseConfig.isConfigured) {
        try {
          final request = AuthRequest(email: email, password: password);
          final response = await FirebaseAuthService.signInWithPassword(FirebaseConfig.apiKey, request);
          _currentUser = User(username: response.email, passwordHash: password, role: 'STAFF');
          _loginError = null;
          _currentScreen = 'BILLING';
          _isFirebaseLoading = false;
          notifyListeners();
          return;
        } catch (_) {
          // Fall through to local auth
        }
      }

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
        try {
          final request = AuthRequest(email: email, password: password);
          await FirebaseAuthService.signUpWithPassword(FirebaseConfig.apiKey, request);
        } catch (_) {
          // Fall through to local registration
        }
      }

      final existing = await _db.getUser(email);
      if (existing != null) {
        _loginError = 'User already exists!';
      } else {
        final newUser = User(username: email, passwordHash: _hashPassword(password), role: 'ADMIN');
        await _db.insertUser(newUser);
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

  void logout() {
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
    if (_cart.isEmpty) return;
    if (_cart.any((item) => item.quantity <= 0)) return;

    final enteredToken = _tokenInput.trim().isEmpty ? '1' : _tokenInput.trim();
    final tokenNum = int.tryParse(enteredToken.replaceAll(RegExp(r'[^0-9]'), ''));
    if (tokenNum == null || tokenNum < 1) return;
    final finalPayment = paymentMethodOverride ?? _selectedPaymentMethod;
    final finalTxnId = gatewayTxnId ?? switch (finalPayment) {
      'UPI' => 'UTR420${DateTime.now().millisecondsSinceEpoch % 1000000000}',
      'Card' => 'RRN580${DateTime.now().millisecondsSinceEpoch % 1000000000}',
      _ => 'CASH${DateTime.now().millisecondsSinceEpoch % 1000000}',
    };

    final order = Order(
      tokenNumber: enteredToken,
      itemsText: CartSerializer.serialize(_cart),
      subTotal: cartSubTotal,
      taxAmount: cartTaxAmount,
      totalAmount: cartTotal,
      paymentMethod: finalPayment,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      dateString: date_utils.DateUtils.getTodayDateString(),
      operatorName: _currentUser?.username ?? 'Staff',
      gatewayTransactionId: finalTxnId,
      gatewayStatus: gatewayStatus,
    );

    await _db.insertOrder(order);
    await refreshData();
    await _resetTokenInputToNextAuto();

    _activeOrderForReceipt = order;
    _cart = [];

    if (autoPrint && _btService.isConnected) {
      await printOrderReceipt(order);
    }

    notifyListeners();
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
    await refreshData();
    if (_activeOrderForReceipt?.id == order.id) {
      _activeOrderForReceipt = updated;
    }
    notifyListeners();
  }

  // Menu Management
  Future<void> saveMenuItem({int? id, required String name, required double rate, required String category, required int openingStock, String description = ''}) async {
    if (id != null && id > 0) {
      final existing = await _db.getMenuItemById(id);
      if (existing != null) {
        final stockDiff = openingStock - existing.openingStock;
        final newRemaining = (existing.remainingStock + stockDiff).clamp(0, openingStock);
        await _db.updateMenuItem(existing.copyWith(
          name: name,
          rate: rate,
          category: category,
          openingStock: openingStock,
          remainingStock: newRemaining,
          description: description,
        ));
      }
    } else {
      await _db.insertMenuItem(MenuItem(
        name: name,
        rate: rate,
        category: category,
        openingStock: openingStock,
        remainingStock: openingStock,
        description: description,
      ));
    }
    await refreshData();
  }

  Future<void> deleteMenuItem(MenuItem item) async {
    await _db.deleteMenuItem(item);
    await refreshData();
  }

  Future<void> quickRestock(MenuItem item) async {
    await _db.updateMenuItem(item.copyWith(usedStock: 0, remainingStock: item.openingStock));
    await refreshData();
  }

  // Expenses
  Future<void> addExpense(String description, double amount) async {
    await _db.insertExpense(Expense(
      description: description,
      amount: amount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      dateString: date_utils.DateUtils.getTodayDateString(),
    ));
    await refreshData();
  }

  Future<void> deleteExpense(Expense expense) async {
    await _db.deleteExpense(expense);
    await refreshData();
  }

  // User Management
  Future<void> createUser(User user) async {
    await _db.insertUser(user);
    await refreshData();
  }

  Future<void> removeUser(User user) async {
    if (user.username == _currentUser?.username || user.username == 'admin') return;
    await _db.deleteUser(user);
    await refreshData();
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

  // ====== BLUETOOTH METHODS ======
  Future<bool> connectBluetooth() async {
    return await _btService.startDiscovery();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await _btService.connect(device);
  }

  void disconnectBluetooth() {
    _btService.disconnect();
    _bluetoothConnected = false;
    notifyListeners();
  }

  Future<bool> printOrderReceipt(Order order) async {
    final lines = _generateReceiptLines(order);
    final success = await _btService.printReceipt(lines);
    if (success) {
      _bluetoothConnected = true;
      notifyListeners();
    }
    return success;
  }

  List<String> _generateReceiptLines(Order order) {
    final items = CartSerializer.deserialize(order.itemsText);
    final lines = <String>[];
    lines.add('');
    lines.add('    COKA BILLING');
    lines.add(' Coimbatore Original');
    lines.add('    Kaalan Adda');
    lines.add('======================');
    lines.add('Token #${order.tokenNumber}');
    lines.add('${order.dateString}  ${_formatReceiptTime(order.timestamp)}');
    lines.add('======================');
    lines.add('');
    lines.add('ITEM           QTY  AMOUNT');
    for (final item in items) {
      final name = item.name.length > 12 ? '${item.name.substring(0, 12)}.' : item.name;
      lines.add('${name.padRight(12)} ${item.quantity.toString().padLeft(3)}  \u20B9${(item.rate * item.quantity).toStringAsFixed(0).padLeft(5)}');
    }
    lines.add('======================');
    lines.add('Subtotal   \u20B9${order.subTotal.toStringAsFixed(2).padLeft(8)}');
    lines.add('GST (5%)   \u20B9${order.taxAmount.toStringAsFixed(2).padLeft(8)}');
    lines.add('TOTAL      \u20B9${order.totalAmount.toStringAsFixed(2).padLeft(8)}');
    lines.add('----------------------');
    lines.add(order.paymentMethod);
    if (order.gatewayTransactionId != null) {
      lines.add('Txn: ${order.gatewayTransactionId}');
    }
    lines.add('Operator: ${order.operatorName}');
    lines.add('======================');
    lines.add('');
    lines.add(' Thank You! Visit Again!');
    lines.add('');
    lines.add('');
    return lines;
  }

  String _formatReceiptTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

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
  Future<void> importBankStatementCsv(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final csv = const CsvToListConverter().convert(content);

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
    } catch (e) {
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
}
