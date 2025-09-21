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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductInfoCard(),
            const SizedBox(height: 16),
            _buildStockCard(),
            const SizedBox(height: 16),
            _buildRecentTransactions(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "product_detail_fab",
        onPressed: () => _navigateToStockTransaction(context),
        label: const Text('Stock Transaction'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.product.name),
            _buildInfoRow('Unit', widget.product.unit),
            _buildInfoRow('Price', '\$${widget.product.price.toStringAsFixed(2)}'),
            _buildInfoRow('Created', DateFormat('MMM dd, yyyy').format(widget.product.createdAt)),
            _buildInfoRow('Updated', DateFormat('MMM dd, yyyy').format(widget.product.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Stock',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FutureBuilder<double>(
              future: context.read<StockProvider>().getProductStockBalance(widget.product.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final stock = snapshot.data ?? 0.0;
                final stockValue = stock * widget.product.price;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${stock.toStringAsFixed(1)} ${widget.product.unit}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: stock > 0 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Value',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '\$${stockValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (stock <= 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Low stock! Consider restocking.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full transaction history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                if (stockProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = stockProvider.transactions.take(5).toList();

                if (transactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: transactions.map((transaction) {
                    return _buildTransactionTile(transaction);
                  }).toList(),
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
    String typeText;

    switch (transaction.type) {
      case StockTransactionType.stockIn:
        typeColor = Colors.green;
        typeIcon = Icons.add_circle;
        typeText = 'Stock In';
        break;
      case StockTransactionType.stockOut:
        typeColor = Colors.red;
        typeIcon = Icons.remove_circle;
        typeText = 'Stock Out';
        break;
      case StockTransactionType.adjustment:
        typeColor = Colors.blue;
        typeIcon = Icons.edit;
        typeText = 'Adjustment';
        break;
    }

    return ListTile(
      leading: Icon(typeIcon, color: typeColor),
      title: Text(typeText),
      subtitle: Text(transaction.reference),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${transaction.quantity.toStringAsFixed(1)} ${widget.product.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
          Text(
            DateFormat('MMM dd').format(transaction.date),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: widget.product),
      ),
    );
  }

  void _navigateToStockTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockTransactionScreen(product: widget.product),
      ),
    );
  }
}