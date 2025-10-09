import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/pdf_service.dart';
import '../../utils/app_strings.dart';
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.deliveryList(isBengali)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterOptions,
                tooltip: AppStrings.filter(isBengali),
              ),
            ],
          ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Consumer<DeliveryProvider>(
              builder: (context, deliveryProvider, child) {
                if (deliveryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredDeliveries = _applyFilters(deliveryProvider.deliveries);

                if (filteredDeliveries.isEmpty) {
                  return _buildEmptyState(context, isBengali);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredDeliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = filteredDeliveries[index];
                    return DeliveryCard(delivery: delivery, isBengali: isBengali);
                  },
                );
              },
            ),
          ),
        ],
      ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "deliveries_fab",
            onPressed: () => _navigateToCreateDelivery(context),
            label: Text(AppStrings.newDelivery(isBengali)),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isBengali) {
    bool isFiltered = _filterStatus != null || _filterShopId != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off_outlined : Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? AppStrings.noDeliveriesFound(isBengali) : AppStrings.createFirstDelivery(isBengali),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? AppStrings.noDeliveriesFound(isBengali)
                : AppStrings.createFirstDelivery(isBengali),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (isFiltered)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _clearFilters,
                child: Text(AppStrings.clear(isBengali)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          if (_filterStatus != null)
            Chip(
              label: Text('Status: ${_filterStatus!.name}'),
              onDeleted: () => setState(() => _filterStatus = null),
            ),
          if (_filterShopId != null)
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final shop = shopProvider.getShopById(_filterShopId!);
                return Chip(
                  label: Text('Shop: ${shop?.name ?? "..."}'),
                  onDeleted: () => setState(() => _filterShopId = null),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Delivery> _applyFilters(List<Delivery> deliveries) {
    return deliveries.where((d) {
      final statusMatch = _filterStatus == null || d.status == _filterStatus;
      final shopMatch = _filterShopId == null || d.shopId == _filterShopId;
      return statusMatch && shopMatch;
    }).toList();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Deliveries', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text('By Status'),
              Wrap(
                spacing: 8.0,
                children: DeliveryStatus.values.map((status) {
                  return FilterChip(
                    label: Text(status.name),
                    selected: _filterStatus == status,
                    onSelected: (selected) {
                      setState(() => _filterStatus = selected ? status : null);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              const Text('By Shop'),
              Expanded(
                child: Consumer<ShopProvider>(
                  builder: (context, shopProvider, child) {
                    return ListView.builder(
                      itemCount: shopProvider.shops.length,
                      itemBuilder: (context, index) {
                        final shop = shopProvider.shops[index];
                        return ListTile(
                          title: Text(shop.name),
                          onTap: () {
                            setState(() => _filterShopId = shop.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _filterShopId = null;
    });
  }

  void _navigateToCreateDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryFormScreen()),
    ).then((_) {
      if (context.mounted) {
        context.read<DeliveryProvider>().loadDeliveries();
      }
    });
  }
}

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final bool isBengali;

  const DeliveryCard({super.key, required this.delivery, required this.isBengali});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>().getShopById(delivery.shopId);

    Color statusColor;
    String statusText;

    switch (delivery.status) {
      case DeliveryStatus.pending:
        statusColor = Colors.orange;
        statusText = AppStrings.pending(isBengali);
        break;
      case DeliveryStatus.completed:
        statusColor = Colors.green;
        statusText = AppStrings.completed(isBengali);
        break;
      case DeliveryStatus.cancelled:
        statusColor = Colors.red;
        statusText = AppStrings.cancelled(isBengali);
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDeliveryDetail(context, delivery),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery #${delivery.id}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (shop != null)
                Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(shop.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(DateFormat.yMMMd().format(delivery.deliveryDate), style: const TextStyle(fontSize: 14)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '৳${delivery.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  Row(
                    children: [
                      if (delivery.status == DeliveryStatus.pending)
                        TextButton.icon(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          label: Text(AppStrings.markAsCompleted(isBengali), style: const TextStyle(color: Colors.green)),
                          onPressed: () => _updateDeliveryStatus(context, delivery, DeliveryStatus.completed),
                        ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                        onPressed: () => _generatePDF(context, delivery),
                        tooltip: 'Generate PDF',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDeliveryDetail(BuildContext context, Delivery delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryDetailScreen(delivery: delivery)),
    );
  }

  void _updateDeliveryStatus(BuildContext context, Delivery delivery, DeliveryStatus status) async {
    // Capture context-dependent references before async gaps
    final deliveryProvider = context.read<DeliveryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Text('Are you sure you want to mark this delivery as ${status.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(status.name, style: TextStyle(color: status == DeliveryStatus.completed ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await deliveryProvider.updateDeliveryStatus(delivery.id!, status);
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Delivery marked as ${status.name}.')),
          );
          deliveryProvider.loadDeliveries();
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _generatePDF(BuildContext context, Delivery delivery) async {
    // ... (PDF generation logic remains the same)
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
          const SnackBar(content: Text('PDF generated and ready to share.')),
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
