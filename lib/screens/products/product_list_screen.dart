import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/product.dart';
import '../../utils/app_strings.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<StockProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.productList(isBengali)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchProducts(isBengali),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                context.read<ProductProvider>().searchProducts(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.products.isEmpty) {
                  return _buildEmptyState(context, productProvider.searchQuery.isNotEmpty, isBengali);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return ProductCard(product: product, isBengali: isBengali);
                  },
                );
              },
            ),
          ),
        ],
      ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "products_fab",
            onPressed: () => _navigateToAddProduct(context),
            label: Text(AppStrings.addProduct(isBengali)),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching, bool isBengali) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? AppStrings.noProductsFound(isBengali) : AppStrings.createFirstProduct(isBengali),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? AppStrings.noProductsFound(isBengali)
                : AppStrings.createFirstProduct(isBengali),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<ProductProvider>().loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isBengali;

  const ProductCard({super.key, required this.product, required this.isBengali});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(context, product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                    child: Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _navigateToEditProduct(context, product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, product),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(AppStrings.price(isBengali), '৳${product.price.toStringAsFixed(2)} / ${product.unit}'),
                  Consumer<StockProvider>(
                    builder: (context, stockProvider, child) {
                      return FutureBuilder<double>(
                        future: stockProvider.getProductStockBalance(product.id!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          final stock = snapshot.data ?? 0.0;
                          return _buildStockStatItem(stock, isBengali);
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStockStatItem(double stock, bool isBengali) {
    Color statusColor;
    if (stock > 10) {
      statusColor = Colors.green;
    } else if (stock > 0) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(AppStrings.currentStock(isBengali), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Text(
              '${stock.toStringAsFixed(1)} units',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.circle, color: statusColor, size: 12),
          ],
        ),
      ],
    );
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _navigateToEditProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<ProductProvider>().loadProducts();
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    final isBengali = Provider.of<LanguageProvider>(context, listen: false).isBengali;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.delete(isBengali)),
        content: Text('Are you sure you want to delete "${product.name}"? Note: Products with stock transactions, deliveries, or returns cannot be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel(isBengali))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(context, product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.delete(isBengali)),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(BuildContext context, Product product) async {
    // Capture context-dependent objects before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await context.read<ProductProvider>().deleteProduct(product.id!);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('"${product.name}" was deleted.')),
        );
        context.read<ProductProvider>().loadProducts();
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error deleting product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
