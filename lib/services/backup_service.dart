import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_service.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../models/delivery.dart';
import '../models/delivery_item.dart';
import '../models/stock_transaction.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();

  Future<String> createBackup() async {
    try {
      await _requestStoragePermission();

      final backupData = await gatherAllData();
      final backupJson = json.encode(backupData);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'stock_tracker_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(backupJson);
      return file.path;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<void> shareBackup() async {
    try {
      final backupPath = await createBackup();
      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'Stock Tracker Backup - ${DateTime.now().toLocal().toString().split(' ')[0]}',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  Future<void> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final backupJson = await file.readAsString();
      final backupData = json.decode(backupJson) as Map<String, dynamic>;

      await _validateBackupData(backupData);
      await _clearAllData();
      await _restoreAllData(backupData);
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  Future<void> clearAllData() async {
    await _databaseService.clearAllData();
  }

  Future<Map<String, dynamic>> gatherAllData() async {
    final products = await _databaseService.getProducts();
    final shops = await _databaseService.getShops();
    final deliveries = await _databaseService.getDeliveries();
    final stockTransactions = await _databaseService.getStockTransactions();

    List<Map<String, dynamic>> deliveryItems = [];
    for (final delivery in deliveries) {
      final items = await _databaseService.getDeliveryItems(delivery.id!);
      deliveryItems.addAll(items.map((item) => {
        ...item.toMap(),
        'delivery_id': delivery.id,
      }));
    }

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'products': products.map((p) => p.toMap()).toList(),
        'shops': shops.map((s) => s.toMap()).toList(),
        'deliveries': deliveries.map((d) => d.toMap()).toList(),
        'delivery_items': deliveryItems,
        'stock_transactions': stockTransactions.map((st) => st.toMap()).toList(),
      }
    };
  }

  Future<void> _validateBackupData(Map<String, dynamic> backupData) async {
    if (!backupData.containsKey('version') || !backupData.containsKey('data')) {
      throw Exception('Invalid backup file format');
    }

    final data = backupData['data'] as Map<String, dynamic>;
    final requiredTables = ['products', 'shops', 'deliveries', 'delivery_items', 'stock_transactions'];

    for (final table in requiredTables) {
      if (!data.containsKey(table)) {
        throw Exception('Backup missing required data: $table');
      }
    }
  }

  Future<void> _clearAllData() async {
    await _databaseService.clearAllData();
  }

  Future<void> _restoreAllData(Map<String, dynamic> backupData) async {
    final data = backupData['data'] as Map<String, dynamic>;

    // Restore products first
    final products = data['products'] as List<dynamic>;
    for (final productMap in products) {
      final product = Product.fromMap(productMap as Map<String, dynamic>);
      await _databaseService.insertProduct(product);
    }

    // Restore shops
    final shops = data['shops'] as List<dynamic>;
    for (final shopMap in shops) {
      final shop = Shop.fromMap(shopMap as Map<String, dynamic>);
      await _databaseService.insertShop(shop);
    }

    // Restore deliveries
    final deliveries = data['deliveries'] as List<dynamic>;
    for (final deliveryMap in deliveries) {
      final delivery = Delivery.fromMap(deliveryMap as Map<String, dynamic>);
      await _databaseService.insertDelivery(delivery);
    }

    // Restore delivery items
    final deliveryItems = data['delivery_items'] as List<dynamic>;
    for (final itemMap in deliveryItems) {
      final item = DeliveryItem.fromMap(itemMap as Map<String, dynamic>);
      await _databaseService.insertDeliveryItem(item);
    }

    // Restore stock transactions
    final stockTransactions = data['stock_transactions'] as List<dynamic>;
    for (final transactionMap in stockTransactions) {
      final transaction = StockTransaction.fromMap(transactionMap as Map<String, dynamic>);
      await _databaseService.insertStockTransaction(transaction);
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().toList();
      return files.where((file) => file.path.contains('stock_tracker_backup_')).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup file: $e');
    }
  }

  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final backupJson = await file.readAsString();
      final backupData = json.decode(backupJson) as Map<String, dynamic>;

      final data = backupData['data'] as Map<String, dynamic>;
      final timestamp = backupData['timestamp'] as String;

      return {
        'timestamp': timestamp,
        'size': await file.length(),
        'products_count': (data['products'] as List).length,
        'shops_count': (data['shops'] as List).length,
        'deliveries_count': (data['deliveries'] as List).length,
        'transactions_count': (data['stock_transactions'] as List).length,
      };
    } catch (e) {
      throw Exception('Failed to read backup info: $e');
    }
  }
}