import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/delivery.dart';
import '../models/stock_transaction.dart';

class CSVService {
  static final CSVService _instance = CSVService._internal();
  factory CSVService() => _instance;
  CSVService._internal();

  final DatabaseService _databaseService = DatabaseService();

  Future<String> exportAllSalesData({bool share = true}) async {
    final csvData = await _generateSalesCSV();
    final fileName = 'sales_data_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    if (share) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sales Data Export - $fileName',
      );
    }

    return file.path;
  }

  Future<String> _generateSalesCSV() async {
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Date,Delivery ID,Shop,Product,Quantity,Unit,Unit Price,Total Price,Status');

    // Get all deliveries with items
    final deliveries = await _databaseService.getDeliveries();

    for (final delivery in deliveries) {
      final shop = await _databaseService.getShop(delivery.shopId);
      final items = await _databaseService.getDeliveryItems(delivery.id!);

      for (final item in items) {
        final product = await _databaseService.getProduct(item.productId);

        if (product != null && shop != null) {
          csv.writeln([
            DateFormat('yyyy-MM-dd').format(delivery.deliveryDate),
            delivery.id,
            _escapeCsvField(shop.name),
            _escapeCsvField(product.name),
            item.quantity.toStringAsFixed(1),
            _escapeCsvField(product.unit),
            item.unitPrice.toStringAsFixed(2),
            item.totalPrice.toStringAsFixed(2),
            _capitalizeFirst(delivery.status.name),
          ].join(','));
        }
      }
    }

    return csv.toString();
  }

  Future<String> exportStockTransactions({bool share = true}) async {
    final csvData = await _generateStockTransactionsCSV();
    final fileName = 'stock_transactions_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    if (share) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Stock Transactions Export - $fileName',
      );
    }

    return file.path;
  }

  Future<String> _generateStockTransactionsCSV() async {
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Date,Product,Transaction Type,Quantity,Unit,Reference');

    // Get all stock transactions
    final transactions = await _databaseService.getStockTransactions();

    for (final transaction in transactions) {
      final product = await _databaseService.getProduct(transaction.productId);

      if (product != null) {
        csv.writeln([
          DateFormat('yyyy-MM-dd HH:mm').format(transaction.date),
          _escapeCsvField(product.name),
          _formatTransactionType(transaction.type),
          transaction.quantity.toStringAsFixed(1),
          _escapeCsvField(product.unit),
          _escapeCsvField(transaction.reference),
        ].join(','));
      }
    }

    return csv.toString();
  }

  Future<String> exportProductSummary({bool share = true}) async {
    final csvData = await _generateProductSummaryCSV();
    final fileName = 'product_summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    if (share) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Product Summary Export - $fileName',
      );
    }

    return file.path;
  }

  Future<String> _generateProductSummaryCSV() async {
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Product,Unit,Current Price,Current Stock,Stock Value,Total Sales,Revenue');

    // Get all products
    final products = await _databaseService.getProducts();

    for (final product in products) {
      final stockBalance = await _databaseService.getProductStockBalance(product.id!);
      final stockValue = stockBalance * product.price;

      // Calculate total sales and revenue
      final deliveries = await _databaseService.getDeliveries();
      double totalSales = 0;
      double totalRevenue = 0;

      for (final delivery in deliveries) {
        if (delivery.status == DeliveryStatus.completed) {
          final items = await _databaseService.getDeliveryItems(delivery.id!);
          for (final item in items) {
            if (item.productId == product.id) {
              totalSales += item.quantity;
              totalRevenue += item.totalPrice;
            }
          }
        }
      }

      csv.writeln([
        _escapeCsvField(product.name),
        _escapeCsvField(product.unit),
        product.price.toStringAsFixed(2),
        stockBalance.toStringAsFixed(1),
        stockValue.toStringAsFixed(2),
        totalSales.toStringAsFixed(1),
        totalRevenue.toStringAsFixed(2),
      ].join(','));
    }

    return csv.toString();
  }

  Future<String> exportShopSummary({bool share = true}) async {
    final csvData = await _generateShopSummaryCSV();
    final fileName = 'shop_summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    if (share) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shop Summary Export - $fileName',
      );
    }

    return file.path;
  }

  Future<String> _generateShopSummaryCSV() async {
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Shop,Address,Contact,Total Orders,Completed Orders,Total Revenue,Average Order Value');

    // Get all shops
    final shops = await _databaseService.getShops();

    for (final shop in shops) {
      final deliveries = await _databaseService.getDeliveries();
      final shopDeliveries = deliveries.where((d) => d.shopId == shop.id).toList();
      final completedDeliveries = shopDeliveries.where((d) => d.status == DeliveryStatus.completed).toList();

      final totalRevenue = completedDeliveries.fold(0.0, (sum, d) => sum + d.totalAmount);
      final averageOrderValue = completedDeliveries.isNotEmpty ? totalRevenue / completedDeliveries.length : 0.0;

      csv.writeln([
        _escapeCsvField(shop.name),
        _escapeCsvField(shop.address),
        _escapeCsvField(shop.contact),
        shopDeliveries.length,
        completedDeliveries.length,
        totalRevenue.toStringAsFixed(2),
        averageOrderValue.toStringAsFixed(2),
      ].join(','));
    }

    return csv.toString();
  }

  String _escapeCsvField(String field) {
    // Escape quotes and wrap in quotes if contains comma, quote, or newline
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _formatTransactionType(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn:
        return 'Stock In';
      case StockTransactionType.stockOut:
        return 'Stock Out';
      case StockTransactionType.adjustment:
        return 'Adjustment';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}