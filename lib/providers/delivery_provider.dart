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

      final db = await _databaseService.database;
      late int deliveryId;

      await db.transaction((txn) async {
        // Validate stock availability before creating delivery
        for (final item in items) {
          final error = await _databaseService.validateStockOperation(item.productId, -item.quantity, db: txn);
          if (error != null) {
            throw Exception('Cannot create delivery: $error');
          }
        }

        deliveryId = await _databaseService.insertDelivery(delivery, db: txn);

        for (final item in items) {
          final deliveryItem = item.copyWith(deliveryId: deliveryId);
          await _databaseService.insertDeliveryItem(deliveryItem, db: txn);

          final stockTransaction = StockTransaction(
            productId: item.productId,
            type: StockTransactionType.stockOut,
            quantity: item.quantity,
            reference: 'Delivery #$deliveryId',
            date: deliveryDate,
          );
          await _databaseService.insertStockTransaction(stockTransaction, db: txn);
        }
      });

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
      final db = await _databaseService.database;
      // Use delivery date for stock transactions to maintain consistent audit trail
      final transactionDate = deliveryDate;

      await db.transaction((txn) async {
        // Get current delivery items to return stock
        final currentItems = await _databaseService.getDeliveryItems(deliveryId, db: txn);

        // Return stock for all current items
        for (final item in currentItems) {
          final stockTransaction = StockTransaction(
            productId: item.productId,
            type: StockTransactionType.stockIn,
            quantity: item.quantity,
            reference: 'Delivery #$deliveryId Edit - Return',
            date: transactionDate,
          );
          await _databaseService.insertStockTransaction(stockTransaction, db: txn);
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
        await _databaseService.updateDelivery(updatedDelivery, db: txn);

        // Delete old delivery items
        await _databaseService.deleteDeliveryItems(deliveryId, db: txn);

        // Validate stock availability for new items (after old stock has been returned)
        for (final item in items) {
          // Calculate current stock after returns have been applied
          final currentBalance = await _databaseService.getProductStockBalance(item.productId, db: txn);
          final projectedBalance = currentBalance - item.quantity;

          if (projectedBalance < 0) {
            throw Exception('Cannot edit delivery: Insufficient stock for product ID ${item.productId}. Current: ${currentBalance.toStringAsFixed(1)}, Required: ${item.quantity.toStringAsFixed(1)}');
          }
        }

        // Insert new delivery items and deduct stock
        for (final item in items) {
          final deliveryItem = item.copyWith(deliveryId: deliveryId);
          await _databaseService.insertDeliveryItem(deliveryItem, db: txn);

          final stockTransaction = StockTransaction(
            productId: item.productId,
            type: StockTransactionType.stockOut,
            quantity: item.quantity,
            reference: 'Delivery #$deliveryId Edit - Deduct',
            date: transactionDate,
          );
          await _databaseService.insertStockTransaction(stockTransaction, db: txn);
        }
      });

      await loadDeliveries();
    } catch (e) {
      debugPrint('Error editing delivery: $e');
      rethrow;
    }
  }

  Future<void> updateDeliveryStatus(int deliveryId, DeliveryStatus status) async {
    try {
      final delivery = _deliveries.firstWhere((d) => d.id == deliveryId);

      // Validate status transition - only PENDING can transition to COMPLETED or CANCELLED
      if (delivery.status != DeliveryStatus.pending) {
        throw Exception('Only pending deliveries can be marked as completed or cancelled. Current status: ${delivery.status.name}');
      }

      final updatedDelivery = delivery.copyWith(status: status);
      final db = await _databaseService.database;

      await db.transaction((txn) async {
        await _databaseService.updateDelivery(updatedDelivery, db: txn);

        // If delivery is being cancelled, return stock to inventory
        // Use delivery date for stock transactions to maintain consistent audit trail
        if (status == DeliveryStatus.cancelled) {
          final items = await _databaseService.getDeliveryItems(deliveryId, db: txn);
          for (final item in items) {
            final stockTransaction = StockTransaction(
              productId: item.productId,
              type: StockTransactionType.stockIn,
              quantity: item.quantity,
              reference: 'Delivery #$deliveryId Cancelled',
              date: delivery.deliveryDate,
            );
            await _databaseService.insertStockTransaction(stockTransaction, db: txn);
          }
        }
      });

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