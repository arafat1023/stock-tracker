import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../models/delivery_item.dart';
import '../models/stock_transaction.dart';
import '../services/database_service.dart';

class DeliveryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Delivery> _deliveries = [];
  bool _isLoading = false;

  List<Delivery> get deliveries => _deliveries;
  bool get isLoading => _isLoading;

  Future<void> loadDeliveries({int? shopId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _deliveries = await _databaseService.getDeliveries(shopId: shopId);
    } catch (e) {
      debugPrint('Error loading deliveries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> createDelivery({
    required int shopId,
    required DateTime deliveryDate,
    required List<DeliveryItem> items,
    required String notes,
  }) async {
    try {
      double totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);

      final delivery = Delivery(
        shopId: shopId,
        deliveryDate: deliveryDate,
        totalAmount: totalAmount,
        status: DeliveryStatus.pending,
        notes: notes,
      );

      final deliveryId = await _databaseService.insertDelivery(delivery);

      for (final item in items) {
        final deliveryItem = item.copyWith(deliveryId: deliveryId);
        await _databaseService.insertDeliveryItem(deliveryItem);

        final stockTransaction = StockTransaction(
          productId: item.productId,
          type: StockTransactionType.stockOut,
          quantity: item.quantity,
          reference: 'Delivery #$deliveryId',
          date: deliveryDate,
        );
        await _databaseService.insertStockTransaction(stockTransaction);
      }

      await loadDeliveries();
      return deliveryId;
    } catch (e) {
      debugPrint('Error creating delivery: $e');
      rethrow;
    }
  }

  Future<void> editDelivery({
    required int deliveryId,
    required int shopId,
    required DateTime deliveryDate,
    required List<DeliveryItem> items,
    required String notes,
  }) async {
    try {
      // Get current delivery items to return stock
      final currentItems = await _databaseService.getDeliveryItems(deliveryId);

      // Return stock for all current items
      for (final item in currentItems) {
        final stockTransaction = StockTransaction(
          productId: item.productId,
          type: StockTransactionType.stockIn,
          quantity: item.quantity,
          reference: 'Delivery #$deliveryId Edit - Return',
          date: DateTime.now(),
        );
        await _databaseService.insertStockTransaction(stockTransaction);
      }

      // Calculate new total amount
      double totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);

      // Update delivery record
      final delivery = _deliveries.firstWhere((d) => d.id == deliveryId);
      final updatedDelivery = delivery.copyWith(
        shopId: shopId,
        deliveryDate: deliveryDate,
        totalAmount: totalAmount,
        notes: notes,
      );
      await _databaseService.updateDelivery(updatedDelivery);

      // Delete old delivery items
      final db = await _databaseService.database;
      await db.delete('delivery_items', where: 'delivery_id = ?', whereArgs: [deliveryId]);

      // Insert new delivery items and deduct stock
      for (final item in items) {
        final deliveryItem = item.copyWith(deliveryId: deliveryId);
        await _databaseService.insertDeliveryItem(deliveryItem);

        final stockTransaction = StockTransaction(
          productId: item.productId,
          type: StockTransactionType.stockOut,
          quantity: item.quantity,
          reference: 'Delivery #$deliveryId Edit - Deduct',
          date: deliveryDate,
        );
        await _databaseService.insertStockTransaction(stockTransaction);
      }

      await loadDeliveries();
    } catch (e) {
      debugPrint('Error editing delivery: $e');
      rethrow;
    }
  }

  Future<void> updateDeliveryStatus(int deliveryId, DeliveryStatus status) async {
    try {
      final delivery = _deliveries.firstWhere((d) => d.id == deliveryId);
      final updatedDelivery = delivery.copyWith(status: status);
      await _databaseService.updateDelivery(updatedDelivery);

      // If delivery is being cancelled, return stock to inventory
      if (status == DeliveryStatus.cancelled) {
        final items = await _databaseService.getDeliveryItems(deliveryId);
        for (final item in items) {
          final stockTransaction = StockTransaction(
            productId: item.productId,
            type: StockTransactionType.stockIn,
            quantity: item.quantity,
            reference: 'Delivery #$deliveryId Cancelled',
            date: DateTime.now(),
          );
          await _databaseService.insertStockTransaction(stockTransaction);
        }
      }

      final index = _deliveries.indexWhere((d) => d.id == deliveryId);
      if (index != -1) {
        _deliveries[index] = updatedDelivery;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
      rethrow;
    }
  }

  Future<List<DeliveryItem>> getDeliveryItems(int deliveryId) async {
    try {
      return await _databaseService.getDeliveryItems(deliveryId);
    } catch (e) {
      debugPrint('Error getting delivery items: $e');
      return [];
    }
  }

  Delivery? getDeliveryById(int id) {
    try {
      return _deliveries.firstWhere((delivery) => delivery.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearData() {
    _deliveries.clear();
    notifyListeners();
  }
}