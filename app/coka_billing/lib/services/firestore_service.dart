import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import '../config/firebase_config.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/expense.dart';
import '../models/cart_item.dart';

final _log = Logger('FirestoreService');

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;
  FirestoreService._();

  bool _initialized = false;
  bool _initInProgress = false;
  bool _orderListening = false;
  bool _menuListening = false;
  bool _expenseListening = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _orderSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _menuSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expenseSubscription;

  bool get isAvailable => _initialized;

  Future<bool> init({bool force = false}) async {
    if (_initialized && !force) return true;
    if (!FirebaseConfig.isConfigured) return false;

    if (force) {
      if (_initInProgress) return false;
      _initInProgress = true;
      try {
        return await _ensureConnected();
      } finally {
        _initInProgress = false;
      }
    }

    try {
      await Firebase.initializeApp(options: FirebaseConfig.toOptions());
      _log.info('Firebase app initialized (awaiting auth for Firestore)');
      return true;
    } catch (e, st) {
      _log.warning('Firebase init failed', e, st);
      return false;
    }
  }

  Future<bool> _ensureConnected() async {
    try {
      Firebase.app();
    } catch (_) {
      await Firebase.initializeApp(options: FirebaseConfig.toOptions());
    }
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await FirebaseFirestore.instance.collection('orders').limit(1).get().timeout(const Duration(seconds: 10));
        _initialized = true;
        _log.info('Firestore connected (attempt $attempt)');
        return true;
      } catch (e) {
        _log.warning('Firestore connect attempt $attempt/3 failed: $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    _initialized = false;
    return false;
  }

  void dispose() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _menuSubscription?.cancel();
    _menuSubscription = null;
    _expenseSubscription?.cancel();
    _expenseSubscription = null;
    _orderListening = false;
    _menuListening = false;
    _expenseListening = false;
  }

  // ─── Orders ───

  Future<bool> saveOrder(Map<String, dynamic> data) async {
    if (!_initialized) return false;
    try {
      final id = data['id'] as int;
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(id.toString())
          .set({...data, 'syncedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      return true;
    } catch (e, st) {
      _log.warning('Firestore saveOrder failed', e, st);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> loadOrders({int limit = 100, DocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    if (!_initialized) return null;
    try {
      var query = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('id', descending: true)
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e, st) {
      _log.warning('Firestore loadOrders failed', e, st);
      return null;
    }
  }

  void listenOrders(void Function(List<Order>) onUpdate) {
    if (!_initialized || _orderListening) return;
    _orderListening = true;
    _orderSubscription?.cancel();
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final orders = snapshot.docs.map((doc) {
        try {
          return Order.fromMap(doc.data());
        } catch (e) {
          _log.warning('Failed to parse order from listener', e);
          return null;
        }
      }).whereType<Order>().toList();
      if (orders.isNotEmpty) onUpdate(orders);
    }, onError: (e) {
      _log.warning('Order listener error, scheduling reconnect', e);
      _orderListening = false;
      _scheduleReconnect('orders', onUpdate);
    });
  }

  void _scheduleReconnect(String collection, dynamic onUpdate) {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_initialized) return;
      switch (collection) {
        case 'orders':
          if (!_orderListening) listenOrders(onUpdate as void Function(List<Order>));
          break;
        case 'menu_items':
          if (!_menuListening) listenMenuItems(onUpdate as void Function(List<MenuItem>));
          break;
        case 'expenses':
          if (!_expenseListening) listenExpenses(onUpdate as void Function(List<Expense>));
          break;
      }
    });
  }

  Future<bool> deleteOrder(int id) async {
    if (!_initialized) return false;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(id.toString()).delete();
      return true;
    } catch (e, st) {
      _log.warning('Firestore deleteOrder failed', e, st);
      return false;
    }
  }

  Future<bool> saveOrderWithStockTransaction(Order order, List<CartItem> cartItems) async {
    if (!_initialized) return false;
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(order.id.toString());
        transaction.set(orderRef, {...order.toMap(), 'syncedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        for (final item in cartItems) {
          final menuRef = FirebaseFirestore.instance.collection('menu_items').doc(item.itemId.toString());
          final menuSnap = await transaction.get(menuRef);
          if (menuSnap.exists) {
            final currentUsed = (menuSnap.data()?['usedStock'] as num?)?.toInt() ?? 0;
            final currentRemaining = (menuSnap.data()?['remainingStock'] as num?)?.toInt() ?? 0;
            transaction.update(menuRef, {
              'usedStock': currentUsed + item.quantity,
              'remainingStock': (currentRemaining - item.quantity).clamp(0, 999999),
              'syncedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
      return true;
    } catch (e, st) {
      _log.warning('Firestore transaction saveOrderWithStock failed', e, st);
      return false;
    }
  }

  // ─── Menu Items ───

  Future<bool> saveMenuItem(Map<String, dynamic> data) async {
    if (!_initialized) return false;
    try {
      final id = data['id'] as int;
      await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(id.toString())
          .set({...data, 'syncedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      return true;
    } catch (e, st) {
      _log.warning('Firestore saveMenuItem failed', e, st);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> loadMenuItems() async {
    if (!_initialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('menu_items')
          .orderBy('name')
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e, st) {
      _log.warning('Firestore loadMenuItems failed', e, st);
      return null;
    }
  }

  Future<bool> deleteMenuItem(int id) async {
    if (!_initialized) return false;
    try {
      await FirebaseFirestore.instance.collection('menu_items').doc(id.toString()).delete();
      return true;
    } catch (e, st) {
      _log.warning('Firestore deleteMenuItem failed', e, st);
      return false;
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? listenMenuItems(void Function(List<MenuItem>) onUpdate) {
    if (!_initialized || _menuListening) return null;
    _menuListening = true;
    _menuSubscription?.cancel();
    _menuSubscription = FirebaseFirestore.instance
        .collection('menu_items')
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        try {
          return MenuItem.fromMap(doc.data());
        } catch (e) {
          _log.warning('Failed to parse menu item from listener', e);
          return null;
        }
      }).whereType<MenuItem>().toList();
      onUpdate(items);
    }, onError: (e) {
      _log.warning('Menu listener error, scheduling reconnect', e);
      _menuListening = false;
      _scheduleReconnect('menu_items', onUpdate);
    });
    return _menuSubscription;
  }

  // ─── Expenses ───

  Future<bool> saveExpense(Map<String, dynamic> data) async {
    if (!_initialized) return false;
    try {
      final id = data['id'] as int;
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(id.toString())
          .set({...data, 'syncedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      return true;
    } catch (e, st) {
      _log.warning('Firestore saveExpense failed', e, st);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> loadExpenses() async {
    if (!_initialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e, st) {
      _log.warning('Firestore loadExpenses failed', e, st);
      return null;
    }
  }

  Future<bool> deleteExpense(int id) async {
    if (!_initialized) return false;
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(id.toString()).delete();
      return true;
    } catch (e, st) {
      _log.warning('Firestore deleteExpense failed', e, st);
      return false;
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? listenExpenses(void Function(List<Expense>) onUpdate) {
    if (!_initialized || _expenseListening) return null;
    _expenseListening = true;
    _expenseSubscription?.cancel();
    _expenseSubscription = FirebaseFirestore.instance
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        try {
          return Expense.fromMap(doc.data());
        } catch (e) {
          _log.warning('Failed to parse expense from listener', e);
          return null;
        }
      }).whereType<Expense>().toList();
      onUpdate(items);
    }, onError: (e) {
      _log.warning('Expense listener error, scheduling reconnect', e);
      _expenseListening = false;
      _scheduleReconnect('expenses', onUpdate);
    });
    return _expenseSubscription;
  }

  // ─── Users ───

  Future<bool> saveUser(Map<String, dynamic> data) async {
    if (!_initialized) return false;
    try {
      final username = data['username'] as String;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .set({...data, 'syncedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      return true;
    } catch (e, st) {
      _log.warning('Firestore saveUser failed', e, st);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> loadUsers() async {
    if (!_initialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e, st) {
      _log.warning('Firestore loadUsers failed', e, st);
      return null;
    }
  }

  Future<bool> deleteUser(String username) async {
    if (!_initialized) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(username).delete();
      return true;
    } catch (e, st) {
      _log.warning('Firestore deleteUser failed', e, st);
      return false;
    }
  }
}
