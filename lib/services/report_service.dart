import '../models/product.dart';
import '../models/shop.dart';
import '../models/delivery.dart';
import '../models/stock_transaction.dart';
import 'database_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Dashboard Metrics
  Future<DashboardMetrics> getDashboardMetrics() async {
    final products = await _databaseService.getProducts();
    final shops = await _databaseService.getShops();
    final deliveries = await _databaseService.getDeliveries();

    final totalProducts = products.length;
    final totalShops = shops.length;
    final totalDeliveries = deliveries.length;
    final pendingDeliveries = deliveries.where((d) => d.status == DeliveryStatus.pending).length;

    double totalStockValue = 0.0;
    for (final product in products) {
      final stock = await _databaseService.getProductStockBalance(product.id!);
      totalStockValue += stock * product.price;
    }

    final totalRevenue = deliveries
        .where((d) => d.status == DeliveryStatus.completed)
        .fold(0.0, (sum, d) => sum + d.totalAmount);

    return DashboardMetrics(
      totalProducts: totalProducts,
      totalShops: totalShops,
      totalDeliveries: totalDeliveries,
      pendingDeliveries: pendingDeliveries,
      totalStockValue: totalStockValue,
      totalRevenue: totalRevenue,
    );
  }

  // Stock Reports
  Future<List<StockBalanceItem>> getStockBalanceReport() async {
    final products = await _databaseService.getProducts();
    final stockItems = <StockBalanceItem>[];

    for (final product in products) {
      final balance = await _databaseService.getProductStockBalance(product.id!);
      final value = balance * product.price;

      stockItems.add(StockBalanceItem(
        product: product,
        currentStock: balance,
        stockValue: value,
        status: balance <= 0 ? StockStatus.outOfStock :
                balance <= 10 ? StockStatus.lowStock : StockStatus.inStock,
      ));
    }

    return stockItems;
  }

  Future<List<StockTransaction>> getStockMovementReport({DateTime? startDate, DateTime? endDate}) async {
    final transactions = await _databaseService.getStockTransactions();

    if (startDate != null || endDate != null) {
      return transactions.where((t) {
        if (startDate != null && t.date.isBefore(startDate)) return false;
        if (endDate != null && t.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    return transactions;
  }

  // Shop Reports
  Future<List<ShopPerformanceItem>> getShopPerformanceReport({DateTime? startDate, DateTime? endDate}) async {
    final shops = await _databaseService.getShops();
    final performanceItems = <ShopPerformanceItem>[];

    for (final shop in shops) {
      final deliveries = await _databaseService.getDeliveries(shopId: shop.id);

      var filteredDeliveries = deliveries;
      if (startDate != null || endDate != null) {
        filteredDeliveries = deliveries.where((d) {
          if (startDate != null && d.deliveryDate.isBefore(startDate)) return false;
          if (endDate != null && d.deliveryDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      final totalDeliveries = filteredDeliveries.length;
      final completedDeliveries = filteredDeliveries.where((d) => d.status == DeliveryStatus.completed).length;
      final totalRevenue = filteredDeliveries
          .where((d) => d.status == DeliveryStatus.completed)
          .fold(0.0, (sum, d) => sum + d.totalAmount);

      performanceItems.add(ShopPerformanceItem(
        shop: shop,
        totalDeliveries: totalDeliveries,
        completedDeliveries: completedDeliveries,
        totalRevenue: totalRevenue,
        averageOrderValue: completedDeliveries > 0 ? totalRevenue / completedDeliveries : 0.0,
      ));
    }

    return performanceItems..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }

  // Product Reports
  Future<List<ProductPerformanceItem>> getProductPerformanceReport({DateTime? startDate, DateTime? endDate}) async {
    final products = await _databaseService.getProducts();
    final deliveries = await _databaseService.getDeliveries();

    // Filter deliveries by date and status once
    final filteredDeliveries = deliveries.where((delivery) {
      if (startDate != null && delivery.deliveryDate.isBefore(startDate)) return false;
      if (endDate != null && delivery.deliveryDate.isAfter(endDate)) return false;
      if (delivery.status != DeliveryStatus.completed) return false;
      return true;
    }).toList();

    // Load all delivery items for filtered deliveries at once
    final Map<int, Map<String, dynamic>> productStats = {};
    for (final product in products) {
      productStats[product.id!] = {
        'quantity': 0.0,
        'revenue': 0.0,
        'count': 0,
      };
    }

    // Process all delivery items in a single pass
    for (final delivery in filteredDeliveries) {
      final items = await _databaseService.getDeliveryItems(delivery.id!);
      for (final item in items) {
        if (productStats.containsKey(item.productId)) {
          productStats[item.productId]!['quantity'] += item.quantity;
          productStats[item.productId]!['revenue'] += item.totalPrice;
          productStats[item.productId]!['count'] += 1;
        }
      }
    }

    // Build performance items from aggregated data
    final performanceItems = <ProductPerformanceItem>[];
    for (final product in products) {
      final stats = productStats[product.id!]!;
      performanceItems.add(ProductPerformanceItem(
        product: product,
        totalQuantityDelivered: stats['quantity'] as double,
        totalRevenue: stats['revenue'] as double,
        deliveryCount: stats['count'] as int,
      ));
    }

    return performanceItems..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }

  // Date-based Analytics
  Future<List<RevenueByDateItem>> getRevenueByDateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final deliveries = await _databaseService.getDeliveries();
    final revenueByDate = <String, double>{};

    for (final delivery in deliveries) {
      if (delivery.deliveryDate.isBefore(startDate) || delivery.deliveryDate.isAfter(endDate)) continue;
      if (delivery.status != DeliveryStatus.completed) continue;

      final dateKey = '${delivery.deliveryDate.year}-${delivery.deliveryDate.month.toString().padLeft(2, '0')}-${delivery.deliveryDate.day.toString().padLeft(2, '0')}';
      revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0.0) + delivery.totalAmount;
    }

    return revenueByDate.entries
        .map((entry) => RevenueByDateItem(
              date: DateTime.parse(entry.key),
              revenue: entry.value,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

// Data Models for Reports
class DashboardMetrics {
  final int totalProducts;
  final int totalShops;
  final int totalDeliveries;
  final int pendingDeliveries;
  final double totalStockValue;
  final double totalRevenue;

  DashboardMetrics({
    required this.totalProducts,
    required this.totalShops,
    required this.totalDeliveries,
    required this.pendingDeliveries,
    required this.totalStockValue,
    required this.totalRevenue,
  });
}

class StockBalanceItem {
  final Product product;
  final double currentStock;
  final double stockValue;
  final StockStatus status;

  StockBalanceItem({
    required this.product,
    required this.currentStock,
    required this.stockValue,
    required this.status,
  });
}

enum StockStatus { inStock, lowStock, outOfStock }

class ShopPerformanceItem {
  final Shop shop;
  final int totalDeliveries;
  final int completedDeliveries;
  final double totalRevenue;
  final double averageOrderValue;

  ShopPerformanceItem({
    required this.shop,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.totalRevenue,
    required this.averageOrderValue,
  });
}

class ProductPerformanceItem {
  final Product product;
  final double totalQuantityDelivered;
  final double totalRevenue;
  final int deliveryCount;

  ProductPerformanceItem({
    required this.product,
    required this.totalQuantityDelivered,
    required this.totalRevenue,
    required this.deliveryCount,
  });
}

class RevenueByDateItem {
  final DateTime date;
  final double revenue;

  RevenueByDateItem({
    required this.date,
    required this.revenue,
  });
}