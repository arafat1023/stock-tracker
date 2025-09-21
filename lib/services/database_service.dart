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

  Future<int> deleteShop(int id) async {
    final db = await database;
    return await db.delete('shops', where: 'id = ?', whereArgs: [id]);
  }

  // Stock Transaction Operations
  Future<int> insertStockTransaction(StockTransaction transaction) async {
    final db = await database;
    return await db.insert('stock_transactions', transaction.toMap());
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

  // Delivery Operations
  Future<int> insertDelivery(Delivery delivery) async {
    final db = await database;
    return await db.insert('deliveries', delivery.toMap());
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

  Future<int> updateDelivery(Delivery delivery) async {
    final db = await database;
    return await db.update(
      'deliveries',
      delivery.toMap(),
      where: 'id = ?',
      whereArgs: [delivery.id],
    );
  }

  // Delivery Item Operations
  Future<int> insertDeliveryItem(DeliveryItem item) async {
    final db = await database;
    return await db.insert('delivery_items', item.toMap());
  }

  Future<List<DeliveryItem>> getDeliveryItems(int deliveryId) async {
    final db = await database;
    final maps = await db.query(
      'delivery_items',
      where: 'delivery_id = ?',
      whereArgs: [deliveryId],
    );
    return List.generate(maps.length, (i) => DeliveryItem.fromMap(maps[i]));
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
      await txn.delete('delivery_items');
      await txn.delete('deliveries');
      await txn.delete('stock_transactions');
      await txn.delete('returns');
      await txn.delete('products');
      await txn.delete('shops');
    });
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}