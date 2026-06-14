import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../platform/db_factory.dart';
import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/expense.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  final userStore = stringMapStoreFactory.store('users');
  final menuItemStore = intMapStoreFactory.store('menu_items');
  final orderStore = intMapStoreFactory.store('orders');
  final expenseStore = intMapStoreFactory.store('expenses');

  Future<Database> _initDatabase() async {
    String dbPath;
    if (kIsWeb) {
      dbPath = 'coka_billing';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = p.join(dir.path, 'coka_billing.db');
    }
    return await platformDbFactory.openDatabase(dbPath);
  }

  Future<void> prepopulateIfNeeded() async {
    final db = await database;

    final userCount = await userStore.count(db);
    if (userCount == 0) {
      final hash = sha256.convert(utf8.encode('admin')).toString();
      await userStore.record('admin').put(db, User(username: 'admin', passwordHash: hash, role: 'ADMIN').toMap());
    }

    final itemCount = await menuItemStore.count(db);
    if (itemCount == 0) {
      final dishes = [
        MenuItem(name: 'COKA Signature Kaalan', rate: 79.0, category: 'Kaalan Dishes', openingStock: 120, remainingStock: 120, description: 'OG street food superstar'),
        MenuItem(name: 'Kaalan Puri Pockets', rate: 89.0, category: 'Kaalan Snacks', openingStock: 100, remainingStock: 100, description: 'Crispy outside, spicy inside'),
        MenuItem(name: 'Kaalan Smash', rate: 89.0, category: 'Kaalan Snacks', openingStock: 80, remainingStock: 80, description: 'Crunch meets comfort'),
        MenuItem(name: 'Cheesy Kaalan Mix', rate: 109.0, category: 'Kaalan Dishes', openingStock: 80, remainingStock: 80, description: 'The crowd favourite'),
        MenuItem(name: 'Egg Kaalan Loaded', rate: 109.0, category: 'Kaalan Dishes', openingStock: 90, remainingStock: 90, description: 'Twice the protein'),
        MenuItem(name: 'Kaalan Bhel Blast', rate: 89.0, category: 'Kaalan Snacks', openingStock: 120, remainingStock: 120, description: 'Light, crunchy, addictive'),
        MenuItem(name: 'Egg-cellent Kaalan Bhel', rate: 109.0, category: 'Kaalan Snacks', openingStock: 85, remainingStock: 85, description: 'Protein meets spice'),
        MenuItem(name: 'BYOB Kaalan Fusion', rate: 119.0, category: 'Kaalan Snacks', openingStock: 75, remainingStock: 75, description: 'Bring Your Own Bite'),
        MenuItem(name: 'Kovai Masala Puri', rate: 69.0, category: 'Kaalan Snacks', openingStock: 110, remainingStock: 110, description: 'Straight from Coimbatore streets'),
        MenuItem(name: 'Egg Bhel Supreme', rate: 89.0, category: 'Kaalan Snacks', openingStock: 95, remainingStock: 95, description: 'Simple. Crunchy. Satisfying'),
        MenuItem(name: 'Water Bottle', rate: 20.0, category: 'Beverages', openingStock: 200, remainingStock: 200, description: 'Chilled mineral water'),
        MenuItem(name: 'Brownie', rate: 49.0, category: 'Desserts', openingStock: 50, remainingStock: 50, description: 'Rich chocolate brownie'),
        MenuItem(name: 'Cold Coffee', rate: 69.0, category: 'Beverages', openingStock: 60, remainingStock: 60, description: 'Iced cold coffee'),
        MenuItem(name: 'Fresh Lime Soda', rate: 39.0, category: 'Beverages', openingStock: 100, remainingStock: 100, description: 'Refreshing lime soda'),
        MenuItem(name: 'Masala Chai', rate: 25.0, category: 'Beverages', openingStock: 150, remainingStock: 150, description: 'Spiced Indian tea'),
        MenuItem(name: 'French Fries', rate: 59.0, category: 'Snacks', openingStock: 80, remainingStock: 80, description: 'Crispy golden fries'),
        MenuItem(name: 'Veg Sandwich', rate: 79.0, category: 'Snacks', openingStock: 40, remainingStock: 40, description: 'Grilled veg sandwich'),
      ];
      for (final dish in dishes) {
        final map = dish.toMap();
        map.remove('id');
        await menuItemStore.add(db, map);
      }
    }
  }

  // User operations
  Future<List<User>> getUsers() async {
    final db = await database;
    final records = await userStore.find(db);
    return records.map((r) => User.fromMap(r.value)).toList();
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    final record = await userStore.record(username).get(db);
    if (record == null) return null;
    return User.fromMap(record);
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await userStore.record(user.username).put(db, user.toMap());
  }

  Future<void> deleteUser(User user) async {
    final db = await database;
    await userStore.record(user.username).delete(db);
  }

  // MenuItem operations
  Future<List<MenuItem>> getMenuItems() async {
    final db = await database;
    final records = await menuItemStore.find(db, finder: Finder(sortOrders: [SortOrder('name')]));
    return records.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return MenuItem.fromMap(map);
    }).toList();
  }

  Future<MenuItem?> getMenuItemById(int id) async {
    final db = await database;
    final record = await menuItemStore.record(id).get(db);
    if (record == null) return null;
    final map = Map<String, dynamic>.from(record);
    map['id'] = id;
    return MenuItem.fromMap(map);
  }

  Future<int> insertMenuItem(MenuItem item) async {
    final db = await database;
    final map = item.toMap();
    map.remove('id');
    return await menuItemStore.add(db, map);
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final db = await database;
    final map = item.toMap();
    map.remove('id');
    await menuItemStore.record(item.id!).put(db, map);
  }

  Future<void> deleteMenuItem(MenuItem item) async {
    final db = await database;
    await menuItemStore.record(item.id!).delete(db);
  }

  // Order operations
  Future<List<Order>> getOrders() async {
    final db = await database;
    final records = await orderStore.find(db, finder: Finder(sortOrders: [SortOrder('timestamp', false)]));
    return records.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return Order.fromMap(map);
    }).toList();
  }

  Future<List<Order>> getOrdersByDate(String dateString) async {
    final db = await database;
    final records = await orderStore.find(
      db,
      finder: Finder(filter: Filter.equals('dateString', dateString), sortOrders: [SortOrder('timestamp', false)]),
    );
    return records.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return Order.fromMap(map);
    }).toList();
  }

  Future<int> insertOrder(Order order) async {
    final db = await database;
    final map = order.toMap();
    map.remove('id');
    final key = await orderStore.add(db, map);
    return key;
  }

  Future<void> updateOrder(Order order) async {
    final db = await database;
    final map = order.toMap();
    map.remove('id');
    await orderStore.record(order.id!).put(db, map);
    if (order.isRefunded) {
      await _adjustStockForRefund(order.itemsText);
    }
  }

  Future<void> clearOrders() async {
    final db = await database;
    await orderStore.delete(db);
  }

  Future<void> clearAndInsertOrders(List<Order> orders) async {
    final db = await database;
    await orderStore.delete(db);
    for (final order in orders) {
      final map = order.toMap();
      map.remove('id');
      await orderStore.add(db, map);
    }
  }

  Future<MenuItem?> _findMenuItem(List<MenuItem> items, int? itemId, String name) {
    if (itemId != null) {
      final byId = items.cast<MenuItem?>().firstWhere(
        (i) => i!.id == itemId,
        orElse: () => null,
      );
      if (byId != null) return Future.value(byId);
    }
    return Future.value(items.cast<MenuItem?>().firstWhere(
      (i) => i!.name.toLowerCase().trim() == name.toLowerCase().trim(),
      orElse: () => null,
    ));
  }

  Future<void> _adjustStockForRefund(String itemsText) async {
    if (itemsText.isEmpty) return;
    final items = itemsText.split('|');
    final allItems = await getMenuItems();

    for (final raw in items) {
      final parts = raw.split('*');
      if (parts.length < 2) continue;
      final name = parts[0];
      final qty = int.tryParse(parts[1]) ?? 0;
      final itemId = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (qty <= 0) continue;

      final match = await _findMenuItem(allItems, itemId, name);
      if (match != null) {
        final newUsed = (match.usedStock - qty).clamp(0, match.openingStock);
        final newRemaining = (match.openingStock - newUsed).clamp(0, match.openingStock);
        await updateMenuItem(match.copyWith(usedStock: newUsed, remainingStock: newRemaining));
      }
    }
  }

  // Expense operations
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final records = await expenseStore.find(db, finder: Finder(sortOrders: [SortOrder('timestamp', false)]));
    return records.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return Expense.fromMap(map);
    }).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final map = expense.toMap();
    map.remove('id');
    return await expenseStore.add(db, map);
  }

  Future<void> deleteExpense(Expense expense) async {
    final db = await database;
    await expenseStore.record(expense.id!).delete(db);
  }
}
