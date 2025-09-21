import 'package:flutter/material.dart';
import '../models/stock_transaction.dart';
import '../services/database_service.dart';

class StockProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<StockTransaction> _transactions = [];
  bool _isLoading = false;

  List<StockTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions({int? productId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _databaseService.getStockTransactions(
        productId: productId,
      );
    } catch (e) {
      debugPrint('Error loading stock transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStockTransaction({
    required int productId,
    required StockTransactionType type,
    required double quantity,
    required String reference,
    DateTime? date,
  }) async {
    try {
      final transaction = StockTransaction(
        productId: productId,
        type: type,
        quantity: quantity,
        reference: reference,
        date: date ?? DateTime.now(),
      );

      await _databaseService.insertStockTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      debugPrint('Error adding stock transaction: $e');
      rethrow;
    }
  }

  Future<double> getProductStockBalance(int productId) async {
    try {
      return await _databaseService.getProductStockBalance(productId);
    } catch (e) {
      debugPrint('Error getting product stock balance: $e');
      return 0.0;
    }
  }

  Future<Map<int, double>> getAllProductStockBalances(List<int> productIds) async {
    Map<int, double> balances = {};

    for (int productId in productIds) {
      try {
        balances[productId] = await _databaseService.getProductStockBalance(productId);
      } catch (e) {
        debugPrint('Error getting stock balance for product $productId: $e');
        balances[productId] = 0.0;
      }
    }

    return balances;
  }
}