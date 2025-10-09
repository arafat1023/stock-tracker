import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class SearchableProductDialog extends StatefulWidget {
  final List<Product> products;
  final String title;
  final List<int>? excludeProductIds;

  const SearchableProductDialog({
    super.key,
    required this.products,
    this.title = 'Select a Product',
    this.excludeProductIds,
  });

  @override
  State<SearchableProductDialog> createState() => _SearchableProductDialogState();
}

class _SearchableProductDialogState extends State<SearchableProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  List<Product> _filteredProducts = [];
  Map<int, double> _stockLevels = {};
  bool _loadingStock = true;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
    _loadStockLevels();
  }

  Future<void> _loadStockLevels() async {
    final productIds = widget.products.map((p) => p.id!).toList();
    final stockLevels = await _databaseService.getAvailableStockForProducts(productIds);
    if (!mounted) return;

    setState(() {
      _stockLevels = stockLevels;
      _loadingStock = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products
            .where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.unit.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: const InputDecoration(
                labelText: 'Search products',
                hintText: 'Type product name or unit...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // Results Count
            if (_searchController.text.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredProducts.length} product(s) found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Product List
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No products available'
                                : 'No products found for "${_searchController.text}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final stock = _stockLevels[product.id] ?? 0.0;
                        final isOutOfStock = stock <= 0;
                        final isLowStock = stock > 0 && stock <= 10;

                        Color stockColor = Colors.green;
                        IconData stockIcon = Icons.check_circle;
                        String stockText = 'In Stock';

                        if (isOutOfStock) {
                          stockColor = Colors.red;
                          stockIcon = Icons.cancel;
                          stockText = 'Out of Stock';
                        } else if (isLowStock) {
                          stockColor = Colors.orange;
                          stockIcon = Icons.warning;
                          stockText = 'Low Stock';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: stockColor.withValues(alpha: 0.1),
                              child: Icon(
                                stockIcon,
                                color: stockColor,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isOutOfStock ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Unit: ${product.unit}'),
                                Text(
                                  'Price: ৳${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_loadingStock)
                                  const Text(
                                    'Loading stock...',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(stockIcon, size: 16, color: stockColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${stock.toStringAsFixed(1)} ${product.unit} - $stockText',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: stockColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: isOutOfStock
                                ? const Icon(Icons.block, color: Colors.red, size: 16)
                                : const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: isOutOfStock
                                ? null
                                : () => Navigator.pop(context, product),
                          ),
                        );
                      },
                    ),
            ),

            // Cancel Button
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}