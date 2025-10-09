import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../models/stock_transaction.dart';
import '../models/delivery.dart';
import '../models/delivery_item.dart';
import '../models/return.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'stock_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onOpen: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        contact TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reference TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE deliveries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id INTEGER NOT NULL,
        delivery_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE delivery_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        delivery_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (delivery_id) REFERENCES deliveries (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        return_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // Product CRUD Operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<bool> canDeleteProduct(int id) async {
    final db = await database;

    // Check if product has stock transactions
    final transactionCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM stock_transactions WHERE product_id = ?', [id])
    ) ?? 0;

    // Check if product is in any delivery items
    final deliveryItemCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM delivery_items WHERE product_id = ?', [id])
    ) ?? 0;

    // Check if product is in any returns
    final returnCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM returns WHERE product_id = ?', [id])
    ) ?? 0;

    return transactionCount == 0 && deliveryItemCount == 0 && returnCount == 0;
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Shop CRUD Operations
  Future<int> insertShop(Shop shop) async {
    final db = await database;
    return await db.insert('shops', shop.toMap());
  }

  Future<List<Shop>> getShops() async {
    final db = await database;
    final maps = await db.query('shops', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Shop.fromMap(maps[i]));
  }

  Future<Shop?> getShop(int id) async {
    final db = await database;
    final maps = await db.query('shops', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Shop.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Shop>> searchShops(String query) async {
    final db = await database;
    final maps = await db.query(
      'shops',
      where: 'name LIKE ? OR address LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Shop.fromMap(maps[i]));
  }

  Future<int> updateShop(Shop shop) async {
    final db = await database;
    return await db.update(
      'shops',
      shop.toMap(),
      where: 'id = ?',
      whereArgs: [shop.id],
    );
  }

  Future<bool> canDeleteShop(int id) async {
    final db = await database;

    // Check if shop has deliveries
    final deliveryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM deliveries WHERE shop_id = ?', [id])
    ) ?? 0;

    // Check if shop has returns
    final returnCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM returns WHERE shop_id = ?', [id])
    ) ?? 0;

    return deliveryCount == 0 && returnCount == 0;
  }

  Future<int> deleteShop(int id) async {
    final db = await database;
    return await db.delete('shops', where: 'id = ?', whereArgs: [id]);
  }

  // Stock Transaction Operations
  Future<int> insertStockTransaction(StockTransaction transaction, {DatabaseExecutor? db}) async {
    final executor = db ?? await database;
    return await executor.insert('stock_transactions', transaction.toMap());
  }

  Future<List<StockTransaction>> getStockTransactions({int? productId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (productId != null) {
      maps = await db.query(
        'stock_transactions',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query('stock_transactions', orderBy: 'date DESC');
    }

    return List.generate(maps.length, (i) => StockTransaction.fromMap(maps[i]));
  }

  Future<double> getProductStockBalance(int productId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN type = 'stockIn' THEN quantity ELSE 0 END) -
        SUM(CASE WHEN type = 'stockOut' THEN quantity ELSE 0 END) +
        SUM(CASE WHEN type = 'adjustment' THEN quantity ELSE 0 END) as balance
      FROM stock_transactions
      WHERE product_id = ?
    ''', [productId]);

    return result.first['balance'] as double? ?? 0.0;
  }

  Future<double> getAvailableStock(int productId) async {
    // Stock is already deducted when deliveries are created (via stockOut transactions)
    // So available stock is simply the stock balance
    return await getProductStockBalance(productId);
  }

  /// Validates that a stock operation won't result in negative stock
  /// Returns error message if invalid, null if valid
  Future<String?> validateStockOperation(int productId, double quantityChange) async {
    final currentBalance = await getProductStockBalance(productId);
    final newBalance = currentBalance + quantityChange; // quantityChange is negative for stockOut

    if (newBalance < 0) {
      return 'Insufficient stock: Current balance is ${currentBalance.toStringAsFixed(1)}, cannot deduct ${(-quantityChange).toStringAsFixed(1)}. Would result in negative stock (${newBalance.toStringAsFixed(1)}).';
    }

    return null;
  }

  Future<Map<int, double>> getAvailableStockForProducts(List<int> productIds) async {
    if (productIds.isEmpty) return {};

    final db = await database;
    final placeholders = List.filled(productIds.length, '?').join(',');

    final result = await db.rawQuery('''
      SELECT
        product_id,
        SUM(CASE WHEN type = 'stockIn' THEN quantity ELSE 0 END) -
        SUM(CASE WHEN type = 'stockOut' THEN quantity ELSE 0 END) +
        SUM(CASE WHEN type = 'adjustment' THEN quantity ELSE 0 END) as balance
      FROM stock_transactions
      WHERE product_id IN ($placeholders)
      GROUP BY product_id
    ''', productIds);

    final Map<int, double> stockMap = {};

    // Initialize all products with 0 balance
    for (final productId in productIds) {
      stockMap[productId] = 0.0;
    }

    // Update with actual balances from query
    for (final row in result) {
      final productId = row['product_id'] as int;
      final balance = row['balance'] as double? ?? 0.0;
      stockMap[productId] = balance;
    }

    return stockMap;
  }

  // Delivery Operations
  Future<int> insertDelivery(Delivery delivery, {DatabaseExecutor? db}) async {
    final executor = db ?? await database;
    return await executor.insert('deliveries', delivery.toMap());
  }

  Future<List<Delivery>> getDeliveries({int? shopId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (shopId != null) {
      maps = await db.query(
        'deliveries',
        where: 'shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'delivery_date DESC',
      );
    } else {
      maps = await db.query('deliveries', orderBy: 'delivery_date DESC');
    }

    return List.generate(maps.length, (i) => Delivery.fromMap(maps[i]));
  }

  Future<int> updateDelivery(Delivery delivery, {DatabaseExecutor? db}) async {
    final executor = db ?? await database;
    return await executor.update(
      'deliveries',
      delivery.toMap(),
      where: 'id = ?',
      whereArgs: [delivery.id],
    );
  }

  // Delivery Item Operations
  Future<int> insertDeliveryItem(DeliveryItem item, {DatabaseExecutor? db}) async {
    final executor = db ?? await database;
    return await executor.insert('delivery_items', item.toMap());
  }

  Future<List<DeliveryItem>> getDeliveryItems(int deliveryId, {DatabaseExecutor? db}) async {
    final executor = db ?? await database;
    final maps = await executor.query(
      'delivery_items',
      where: 'delivery_id = ?',
      whereArgs: [deliveryId],
    );
    return List.generate(maps.length, (i) => DeliveryItem.fromMap(maps[i]));
  }

  Future<int> deleteDeliveryItems(int deliveryId, {DatabaseExecutor? db}) async {
    final executor = db ?? await database;
    return await executor.delete(
      'delivery_items',
      where: 'delivery_id = ?',
      whereArgs: [deliveryId],
    );
  }

  // Return Operations
  Future<int> insertReturn(Return returnItem) async {
    final db = await database;
    return await db.insert('returns', returnItem.toMap());
  }

  Future<List<Return>> getReturns({int? shopId, int? productId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (shopId != null && productId != null) {
      maps = await db.query(
        'returns',
        where: 'shop_id = ? AND product_id = ?',
        whereArgs: [shopId, productId],
        orderBy: 'return_date DESC',
      );
    } else if (shopId != null) {
      maps = await db.query(
        'returns',
        where: 'shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'return_date DESC',
      );
    } else if (productId != null) {
      maps = await db.query(
        'returns',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'return_date DESC',
      );
    } else {
      maps = await db.query('returns', orderBy: 'return_date DESC');
    }

    return List.generate(maps.length, (i) => Return.fromMap(maps[i]));
  }

  // Data Management
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all data
      await txn.delete('delivery_items');
      await txn.delete('deliveries');
      await txn.delete('stock_transactions');
      await txn.delete('returns');
      await txn.delete('products');
      await txn.delete('shops');

      // Reset auto-increment counters by updating sqlite_sequence table
      await txn.delete('sqlite_sequence');

      // Alternative approach: Update each table's sequence to 0
      await txn.rawUpdate("UPDATE sqlite_sequence SET seq = 0 WHERE name IN ('products', 'shops', 'deliveries', 'delivery_items', 'stock_transactions', 'returns')");
    });
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}