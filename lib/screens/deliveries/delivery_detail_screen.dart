import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery.dart';
import '../../models/delivery_item.dart';
import '../../models/product.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_strings.dart';
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
      if (mounted) {
        setState(() {
          _deliveryItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorLoadingItems(context.read<LanguageProvider>().isBengali)}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text('${AppStrings.delivery(isBengali)} #${widget.delivery.id}'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                onPressed: () => _generatePDF(isBengali),
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: AppStrings.generatePDF(isBengali),
              ),
            ],
          ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDeliveryItems,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeliveryInfoCard(isBengali),
                      const SizedBox(height: 16),
                      _buildItemsCard(isBengali),
                      const SizedBox(height: 16),
                      if (widget.delivery.status == DeliveryStatus.pending)
                        _buildActionsCard(isBengali),
                    ],
                  ),
                ),
              ),
      );
      },
    );
  }

  Widget _buildDeliveryInfoCard(bool isBengali) {
    Color statusColor;
    String statusText;
    switch (widget.delivery.status) {
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

    final shop = context.watch<ShopProvider>().getShopById(widget.delivery.shopId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.deliveryDetails(isBengali),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
            const Divider(height: 24),
            _buildInfoRow(Icons.store, AppStrings.shop(isBengali), shop?.name ?? AppStrings.notAvailable(isBengali)),
            _buildInfoRow(Icons.calendar_today, AppStrings.date(isBengali), DateFormat.yMMMd().format(widget.delivery.deliveryDate)),
            _buildInfoRow(Icons.attach_money, AppStrings.totalAmount(isBengali), '৳${widget.delivery.totalAmount.toStringAsFixed(2)}'),
            if (widget.delivery.notes.isNotEmpty)
              _buildInfoRow(Icons.notes, AppStrings.notes(isBengali), widget.delivery.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(bool isBengali) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.items(isBengali)} (${_deliveryItems.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_deliveryItems.isEmpty)
              Center(child: Text(AppStrings.noItemsInDelivery(isBengali), style: const TextStyle(color: Colors.grey)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _deliveryItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildItemTile(_deliveryItems[index], isBengali);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(DeliveryItem item, bool isBengali) {
    final product = context.watch<ProductProvider>().getProductById(item.productId);
    return ListTile(
      title: Text(product?.name ?? AppStrings.unknownProduct(isBengali), style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${item.quantity.toStringAsFixed(1)} ${product?.unit ?? ''} x ৳${item.unitPrice.toStringAsFixed(2)}'),
      trailing: Text('৳${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildActionsCard(bool isBengali) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.actions(isBengali), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateDeliveryStatus(DeliveryStatus.completed, isBengali),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(AppStrings.markAsCompleted(isBengali)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateDeliveryStatus(DeliveryStatus.cancelled, isBengali),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: Text(AppStrings.cancelDelivery(isBengali)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _updateDeliveryStatus(DeliveryStatus status, bool isBengali) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.confirmAction(isBengali)),
        content: Text(AppStrings.confirmDeliveryStatusChange(isBengali, status == DeliveryStatus.completed)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.no(isBengali))),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: status == DeliveryStatus.completed ? Colors.green : Colors.red), child: Text(AppStrings.yes(isBengali))),
        ],
      ),
    );

    if (confirmed == true) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final deliveryProvider = context.read<DeliveryProvider>();

      try {
        await deliveryProvider.updateDeliveryStatus(widget.delivery.id!, status);
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(content: Text(AppStrings.deliveryStatusUpdated(isBengali, status.name)), backgroundColor: Colors.green),
        );
        navigator.pop(true); // Return true to indicate success
      } catch (e) {
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(content: Text('${AppStrings.error(isBengali)}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _generatePDF(bool isBengali) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.pdfOptions(isBengali)),
        content: Text(AppStrings.pdfOptionsDescription(isBengali)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(AppStrings.cancel(isBengali)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'download'),
            icon: const Icon(Icons.download),
            label: Text(AppStrings.download(isBengali)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'share'),
            icon: const Icon(Icons.share),
            label: Text(AppStrings.share(isBengali)),
          ),
        ],
      ),
    );

    if (action == null || action == 'cancel') return;

    try {
      final shop = context.read<ShopProvider>().getShopById(widget.delivery.shopId);
      if (shop == null) throw Exception('Shop not found');

      final products = _deliveryItems.map((item) {
        return context.read<ProductProvider>().getProductById(item.productId) ?? Product.fromMap({
          'id': 0,
          'name': 'Unknown',
          'unit': '',
          'price': 0.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }).toList();

      final pdfService = PDFService();
      final filePath = await pdfService.generateDeliveryNote(
        delivery: widget.delivery,
        shop: shop,
        items: _deliveryItems,
        products: products,
        share: action == 'share',
        download: action == 'download',
      );

      if (!mounted) return;

      if (action == 'download' && filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.pdfDownloadedTo(isBengali)}: $filePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (action == 'share') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.pdfGeneratedAndReady(isBengali))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorGeneratingPDF(isBengali)}: $e'), backgroundColor: Colors.red),
        );
    }
  }
}
