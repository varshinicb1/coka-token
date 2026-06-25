import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import '../config/firebase_config.dart';
import '../models/order.dart';

final _log = Logger('FirestoreService');

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;
  FirestoreService._();

  bool _initialized = false;
  bool _listening = false;
  bool _initInProgress = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _orderSubscription;

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
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await Firebase.initializeApp(options: FirebaseConfig.toOptions());
        await FirebaseFirestore.instance.collection('orders').limit(1).get().timeout(const Duration(seconds: 10));
        _initialized = true;
        _log.info('Firestore connected (attempt $attempt)');
        return true;
      } catch (e) {
        _log.warning('Firestore connect attempt $attempt/3 failed: $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    try {
      Firebase.app();
      await FirebaseFirestore.instance.collection('orders').limit(1).get().timeout(const Duration(seconds: 10));
      _initialized = true;
      _log.info('Firestore connected on retry after re-init');
      return true;
    } catch (e) {
      _log.warning('Firestore final retry failed: $e');
    }

    _initialized = false;
    return false;
  }

  void dispose() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _listening = false;
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

  Future<List<Map<String, dynamic>>?> loadOrders() async {
    if (!_initialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('id', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e, st) {
      _log.warning('Firestore loadOrders failed', e, st);
      return null;
    }
  }

  void listenOrders(void Function(List<Order>) onUpdate) {
    if (!_initialized || _listening) return;
    _listening = true;
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
      _log.warning('Order listener error', e);
      _listening = false;
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
}
