import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../models/stock_transaction.dart';
import '../../providers/stock_provider.dart';
import 'product_form_screen.dart';
import 'stock_transaction_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadTransactions(productId: widget.product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _navigateToEdit(context),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Product',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStockCard(),
              const SizedBox(height: 16),
              _buildProductInfoCard(),
              const SizedBox(height: 16),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "product_detail_fab",
        onPressed: () => _navigateToStockTransaction(context),
        label: const Text('New Stock Entry'),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Future<void> _refreshData() async {
    await context.read<StockProvider>().loadTransactions(productId: widget.product.id);
  }

  Widget _buildProductInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.label, 'Unit', widget.product.unit),
            _buildInfoRow(Icons.attach_money, 'Price', '৳${widget.product.price.toStringAsFixed(2)}'),
            _buildInfoRow(Icons.calendar_today, 'Created On', DateFormat.yMMMd().format(widget.product.createdAt)),
            _buildInfoRow(Icons.edit_calendar, 'Last Updated', DateFormat.yMMMd().format(widget.product.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<double>(
          future: context.read<StockProvider>().getProductStockBalance(widget.product.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stock = snapshot.data ?? 0.0;

            Color statusColor;
            String statusText;
            if (stock > 10) {
              statusColor = Colors.green;
              statusText = 'In Stock';
            } else if (stock > 0) {
              statusColor = Colors.orange;
              statusText = 'Low Stock';
            } else {
              statusColor = Colors.red;
              statusText = 'Out of Stock';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Inventory',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStockMetric('Quantity', '${stock.toStringAsFixed(1)} ${widget.product.unit}'),
                    _buildStockMetric('Value', '৳${(stock * widget.product.price).toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStockMetric(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Stock History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                if (stockProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = stockProvider.transactions.take(5).toList();

                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No transactions recorded yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return Column(
                  children: transactions.map((t) => _buildTransactionTile(t)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(StockTransaction transaction) {
    Color typeColor;
    IconData typeIcon;
    String sign;

    switch (transaction.type) {
      case StockTransactionType.stockIn:
        typeColor = Colors.green;
        typeIcon = Icons.arrow_upward;
        sign = '+';
        break;
      case StockTransactionType.stockOut:
        typeColor = Colors.red;
        typeIcon = Icons.arrow_downward;
        sign = '-';
        break;
      case StockTransactionType.adjustment:
        typeColor = Colors.blue;
        typeIcon = Icons.sync_alt;
        sign = '~';
        break;
    }

    return ListTile(
      leading: CircleAvatar(backgroundColor: typeColor, child: Icon(typeIcon, color: Colors.white, size: 20)),
      title: Text(transaction.reference, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
      trailing: Text(
        '$sign${transaction.quantity.toStringAsFixed(1)} ${widget.product.unit}',
        style: TextStyle(fontWeight: FontWeight.bold, color: typeColor, fontSize: 16),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductFormScreen(product: widget.product)),
    ).then((_) => _refreshData());
  }

  void _navigateToStockTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockTransactionScreen(product: widget.product)),
    ).then((_) => _refreshData());
  }
}
