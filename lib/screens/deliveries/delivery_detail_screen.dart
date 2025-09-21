import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery.dart';
import '../../models/delivery_item.dart';
import '../../models/product.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/pdf_service.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryDetailScreen({super.key, required this.delivery});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  List<DeliveryItem> _deliveryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryItems();
  }

  Future<void> _loadDeliveryItems() async {
    try {
      final items = await context.read<DeliveryProvider>().getDeliveryItems(widget.delivery.id!);
      setState(() {
        _deliveryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${widget.delivery.id}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.delivery.status == DeliveryStatus.pending)
            PopupMenuButton<String>(
              onSelected: _handleAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'complete',
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Mark Completed'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text('Cancel Delivery'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          IconButton(
            onPressed: _generatePDF,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryInfoCard(),
                  const SizedBox(height: 16),
                  _buildShopInfoCard(),
                  const SizedBox(height: 16),
                  _buildItemsCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    Color statusColor;
    IconData statusIcon;

    switch (widget.delivery.status) {
      case DeliveryStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case DeliveryStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case DeliveryStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Status: ${widget.delivery.status.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Delivery Date', DateFormat('MMM dd, yyyy').format(widget.delivery.deliveryDate)),
            _buildInfoRow('Total Amount', '\$${widget.delivery.totalAmount.toStringAsFixed(2)}'),
            if (widget.delivery.notes.isNotEmpty)
              _buildInfoRow('Notes', widget.delivery.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final shop = shopProvider.getShopById(widget.delivery.shopId);
                if (shop == null) {
                  return const Text('Shop not found');
                }

                return Column(
                  children: [
                    _buildInfoRow('Name', shop.name),
                    _buildInfoRow('Address', shop.address),
                    if (shop.contact.isNotEmpty)
                      _buildInfoRow('Contact', shop.contact),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${_deliveryItems.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_deliveryItems.isEmpty)
              const Center(
                child: Text(
                  'No items found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: _deliveryItems.map((item) {
                  return _buildItemTile(item);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(DeliveryItem item) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final product = productProvider.getProductById(item.productId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product?.name ?? 'Unknown Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Quantity: ${item.quantity.toStringAsFixed(1)} ${product?.unit ?? ''}'),
                  const Spacer(),
                  Text('Unit Price: \$${item.unitPrice.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    final itemCount = _deliveryItems.length;
    final totalQuantity = _deliveryItems.fold(0.0, (sum, item) => sum + item.quantity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Items',
                    itemCount.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Quantity',
                    totalQuantity.toStringAsFixed(1),
                    Icons.straighten,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.delivery.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            width: 100,
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

  void _handleAction(String action) {
    switch (action) {
      case 'complete':
        _updateDeliveryStatus(DeliveryStatus.completed);
        break;
      case 'cancel':
        _updateDeliveryStatus(DeliveryStatus.cancelled);
        break;
    }
  }

  void _updateDeliveryStatus(DeliveryStatus status) async {
    try {
      await context.read<DeliveryProvider>().updateDeliveryStatus(widget.delivery.id!, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery ${status.name} successfully')),
        );
        Navigator.pop(context); // Return to delivery list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating delivery: $e')),
        );
      }
    }
  }

  void _generatePDF() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate PDF'),
        content: const Text('Choose an action for the delivery note:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createAndPrintPDF(false);
            },
            child: const Text('Print'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createAndPrintPDF(true);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _createAndPrintPDF(bool share) async {
    try {
      final shopProvider = context.read<ShopProvider>();
      final productProvider = context.read<ProductProvider>();

      final shop = shopProvider.getShopById(widget.delivery.shopId);
      if (shop == null) {
        throw Exception('Shop not found');
      }

      final products = <Product>[];
      for (final item in _deliveryItems) {
        final product = productProvider.getProductById(item.productId);
        if (product != null) {
          products.add(product);
        }
      }

      final pdfService = PDFService();
      await pdfService.generateDeliveryNote(
        delivery: widget.delivery,
        shop: shop,
        items: _deliveryItems,
        products: products,
        share: share,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(share ? 'PDF shared successfully' : 'PDF generated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}