import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
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

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'coka_billing.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rate REAL NOT NULL,
        category TEXT NOT NULL,
        openingStock INTEGER NOT NULL,
        usedStock INTEGER NOT NULL DEFAULT 0,
        remainingStock INTEGER NOT NULL DEFAULT 0,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tokenNumber TEXT NOT NULL,
        itemsText TEXT NOT NULL,
        subTotal REAL NOT NULL,
        taxAmount REAL NOT NULL,
        totalAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        dateString TEXT NOT NULL,
        operatorName TEXT NOT NULL,
        isRefunded INTEGER NOT NULL DEFAULT 0,
        gatewayTransactionId TEXT,
        gatewayStatus TEXT,
        reconciled INTEGER NOT NULL DEFAULT 0,
        reconciledAt INTEGER NOT NULL DEFAULT 0,
        bankStatementMatchId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        dateString TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS menu_items');
      await db.execute('DROP TABLE IF EXISTS orders');
      await db.execute('DROP TABLE IF EXISTS expenses');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> prepopulateIfNeeded() async {
    final db = await database;

    final userCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM users')).first['c'] as int;
    if (userCount == 0) {
      final hash = sha256.convert(utf8.encode('admin')).toString();
      await db.insert('users', User(username: 'admin', passwordHash: hash, role: 'ADMIN').toMap());
    }

    final itemCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM menu_items')).first['c'] as int;
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
      ];
      for (final dish in dishes) {
        await db.insert('menu_items', dish.toMap()..remove('id'));
      }
    }
  }

  // User operations
  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteUser(User user) async {
    final db = await database;
    await db.delete('users', where: 'username = ?', whereArgs: [user.username]);
  }

  // MenuItem operations
  Future<List<MenuItem>> getMenuItems() async {
    final db = await database;
    final maps = await db.query('menu_items', orderBy: 'name ASC');
    return maps.map((m) => MenuItem.fromMap(m)).toList();
  }

  Future<MenuItem?> getMenuItemById(int id) async {
    final db = await database;
    final maps = await db.query('menu_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return MenuItem.fromMap(maps.first);
  }

  Future<void> insertMenuItem(MenuItem item) async {
    final db = await database;
    await db.insert('menu_items', item.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final db = await database;
    await db.update('menu_items', item.toMap()..remove('id'), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteMenuItem(MenuItem item) async {
    final db = await database;
    await db.delete('menu_items', where: 'id = ?', whereArgs: [item.id]);
  }

  // Order operations
  Future<List<Order>> getOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'timestamp DESC');
    return maps.map((m) => Order.fromMap(m)).toList();
  }

  Future<List<Order>> getOrdersByDate(String dateString) async {
    final db = await database;
    final maps = await db.query('orders', where: 'dateString = ?', whereArgs: [dateString], orderBy: 'timestamp DESC');
    return maps.map((m) => Order.fromMap(m)).toList();
  }

  Future<int> insertOrder(Order order) async {
    final db = await database;
    final id = await db.insert('orders', order.toMap()..remove('id'));
    await _adjustStockForOrder(order.itemsText);
    return id;
  }

  Future<void> updateOrder(Order order) async {
    final db = await database;
    await db.update('orders', order.toMap()..remove('id'), where: 'id = ?', whereArgs: [order.id]);
    if (order.isRefunded) {
      await _adjustStockForRefund(order.itemsText);
    }
  }

  Future<void> clearOrders() async {
    final db = await database;
    await db.delete('orders');
  }

  Future<MenuItem?> _findMenuItem(List<MenuItem> items, int? itemId, String name) {
    if (itemId != null) {
      final byId = items.cast<MenuItem?>().firstWhere(
        (i) => i!.id == itemId,
        orElse: () => null,
      );
      if (byId != null) return byId;
    }
    return items.cast<MenuItem?>().firstWhere(
      (i) => i!.name.toLowerCase().trim() == name.toLowerCase().trim(),
      orElse: () => null,
    );
  }

  Future<void> _adjustStockForOrder(String itemsText) async {
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

      final match = _findMenuItem(allItems, itemId, name);
      if (match != null) {
        final newUsed = match.usedStock + qty;
        final newRemaining = (match.openingStock - newUsed).clamp(0, match.openingStock);
        await updateMenuItem(match.copyWith(usedStock: newUsed, remainingStock: newRemaining));
      }
    }
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

      final match = _findMenuItem(allItems, itemId, name);
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
    final maps = await db.query('expenses', orderBy: 'timestamp DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<void> deleteExpense(Expense expense) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expense.id]);
  }
}
