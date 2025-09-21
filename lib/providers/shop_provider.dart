import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../services/database_service.dart';

class ShopProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Shop> _shops = [];
  List<Shop> _filteredShops = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Shop> get shops => _filteredShops;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadShops() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shops = await _databaseService.getShops();
      _applySearch();
    } catch (e) {
      debugPrint('Error loading shops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addShop(Shop shop) async {
    try {
      final id = await _databaseService.insertShop(shop);
      final newShop = shop.copyWith(id: id);
      _shops.add(newShop);
      _applySearch();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding shop: $e');
      rethrow;
    }
  }

  Future<void> updateShop(Shop shop) async {
    try {
      await _databaseService.updateShop(shop);
      final index = _shops.indexWhere((s) => s.id == shop.id);
      if (index != -1) {
        _shops[index] = shop;
        _applySearch();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating shop: $e');
      rethrow;
    }
  }

  Future<void> deleteShop(int id) async {
    try {
      await _databaseService.deleteShop(id);
      _shops.removeWhere((shop) => shop.id == id);
      _applySearch();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting shop: $e');
      rethrow;
    }
  }

  void searchShops(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredShops = List.from(_shops);
    } else {
      _filteredShops = _shops
          .where((shop) =>
              shop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              shop.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  Shop? getShopById(int id) {
    try {
      return _shops.firstWhere((shop) => shop.id == id);
    } catch (e) {
      return null;
    }
  }
}