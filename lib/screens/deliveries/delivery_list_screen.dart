import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/pdf_service.dart';
import 'delivery_form_screen.dart';
import 'delivery_detail_screen.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  DeliveryStatus? _filterStatus;
  int? _filterShopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadDeliveries();
      context.read<ShopProvider>().loadShops();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleFilterAction,
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Deliveries'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Only'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed Only'),
              ),
              const PopupMenuItem(
                value: 'shop',
                child: Text('Filter by Shop'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, deliveryProvider, child) {
          if (deliveryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var filteredDeliveries = _applyFilters(deliveryProvider.deliveries);

          if (filteredDeliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_filterStatus != null || _filterShopId != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_filterStatus != null || _filterShopId != null)
                _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDeliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = filteredDeliveries[index];
                    return DeliveryListTile(delivery: delivery);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDelivery(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getEmptyStateMessage() {
    if (_filterStatus != null || _filterShopId != null) {
      return 'No deliveries match your filters.';
    }
    return 'No deliveries found.\nTap + to create your first delivery.';
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_filterStatus != null)
            Chip(
              label: Text('Status: ${_filterStatus!.name.toUpperCase()}'),
              onDeleted: () => setState(() => _filterStatus = null),
            ),
          if (_filterShopId != null)
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final shop = shopProvider.getShopById(_filterShopId!);
                return Chip(
                  label: Text('Shop: ${shop?.name ?? 'Unknown'}'),
                  onDeleted: () => setState(() => _filterShopId = null),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Delivery> _applyFilters(List<Delivery> deliveries) {
    var filtered = deliveries;

    if (_filterStatus != null) {
      filtered = filtered.where((d) => d.status == _filterStatus).toList();
    }

    if (_filterShopId != null) {
      filtered = filtered.where((d) => d.shopId == _filterShopId).toList();
    }

    return filtered;
  }

  void _handleFilterAction(String action) {
    switch (action) {
      case 'all':
        _clearFilters();
        break;
      case 'pending':
        setState(() {
          _filterStatus = DeliveryStatus.pending;
        });
        break;
      case 'completed':
        setState(() {
          _filterStatus = DeliveryStatus.completed;
        });
        break;
      case 'shop':
        _showShopFilterDialog();
        break;
    }
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _filterShopId = null;
    });
  }

  void _showShopFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          return AlertDialog(
            title: const Text('Filter by Shop'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: shopProvider.shops.length,
                itemBuilder: (context, index) {
                  final shop = shopProvider.shops[index];
                  return ListTile(
                    title: Text(shop.name),
                    subtitle: Text(shop.address),
                    onTap: () {
                      setState(() {
                        _filterShopId = shop.id;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToCreateDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryFormScreen(),
      ),
    );
  }
}

class DeliveryListTile extends StatelessWidget {
  final Delivery delivery;

  const DeliveryListTile({
    super.key,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (delivery.status) {
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Delivery #${delivery.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '\$${delivery.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final shop = shopProvider.getShopById(delivery.shopId);
                return Text(
                  'Shop: ${shop?.name ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                );
              },
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(delivery.deliveryDate)}',
            ),
            if (delivery.notes.isNotEmpty)
              Text(
                delivery.notes,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, delivery),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (delivery.status == DeliveryStatus.pending)
              const PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Mark Completed', style: TextStyle(color: Colors.green)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (delivery.status == DeliveryStatus.pending)
              const PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Cancel Delivery', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'pdf',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.blue),
                title: Text('Generate PDF', style: TextStyle(color: Colors.blue)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToDeliveryDetail(context, delivery),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Delivery delivery) {
    switch (action) {
      case 'view':
        _navigateToDeliveryDetail(context, delivery);
        break;
      case 'complete':
        _updateDeliveryStatus(context, delivery, DeliveryStatus.completed);
        break;
      case 'cancel':
        _updateDeliveryStatus(context, delivery, DeliveryStatus.cancelled);
        break;
      case 'pdf':
        _generatePDF(context, delivery);
        break;
    }
  }

  void _navigateToDeliveryDetail(BuildContext context, Delivery delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(delivery: delivery),
      ),
    );
  }

  void _updateDeliveryStatus(BuildContext context, Delivery delivery, DeliveryStatus status) async {
    try {
      await context.read<DeliveryProvider>().updateDeliveryStatus(delivery.id!, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery ${status.name} successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating delivery: $e')),
        );
      }
    }
  }

  void _generatePDF(BuildContext context, Delivery delivery) async {
    try {
      final deliveryProvider = context.read<DeliveryProvider>();
      final shopProvider = context.read<ShopProvider>();
      final productProvider = context.read<ProductProvider>();

      final shop = shopProvider.getShopById(delivery.shopId);
      if (shop == null) {
        throw Exception('Shop not found');
      }

      final deliveryItems = await deliveryProvider.getDeliveryItems(delivery.id!);
      final products = <Product>[];

      for (final item in deliveryItems) {
        final product = productProvider.getProductById(item.productId);
        if (product != null) {
          products.add(product);
        }
      }

      final pdfService = PDFService();
      await pdfService.generateDeliveryNote(
        delivery: delivery,
        shop: shop,
        items: deliveryItems,
        products: products,
        share: true,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated and shared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
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