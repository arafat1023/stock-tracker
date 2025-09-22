import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/shop.dart';
import '../../models/delivery.dart';
import '../../providers/delivery_provider.dart';
import 'shop_form_screen.dart';
import '../deliveries/delivery_form_screen.dart';
import '../deliveries/delivery_detail_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await context.read<DeliveryProvider>().loadDeliveries(shopId: widget.shop.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _navigateToEdit(context),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Shop',
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
              _buildShopInfoCard(),
              const SizedBox(height: 16),
              _buildDeliveryStatsCard(),
              const SizedBox(height: 16),
              _buildRecentDeliveries(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "shop_detail_fab",
        onPressed: () => _createDelivery(context),
        label: const Text('New Delivery'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.store, 'Name', widget.shop.name),
            _buildInfoRow(Icons.location_on, 'Address', widget.shop.address),
            if (widget.shop.contact.isNotEmpty)
              _buildInfoRow(Icons.phone, 'Contact', widget.shop.contact),
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

  Widget _buildDeliveryStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<DeliveryProvider>(
          builder: (context, deliveryProvider, child) {
            final deliveries = deliveryProvider.deliveries.where((d) => d.shopId == widget.shop.id).toList();
            final totalValue = deliveries.where((d) => d.status == DeliveryStatus.completed).fold(0.0, (sum, d) => sum + d.totalAmount);
            final pendingCount = deliveries.where((d) => d.status == DeliveryStatus.pending).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatMetric('Total Deliveries', deliveries.length.toString()),
                    _buildStatMetric('Total Sales', '৳${totalValue.toStringAsFixed(2)}'),
                    _buildStatMetric('Pending', pendingCount.toString(), color: Colors.orange),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatMetric(String title, String value, {Color? color}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRecentDeliveries() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Deliveries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<DeliveryProvider>(
              builder: (context, deliveryProvider, child) {
                final deliveries = deliveryProvider.deliveries.where((d) => d.shopId == widget.shop.id).take(5).toList();

                if (deliveries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No deliveries recorded for this shop yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return Column(
                  children: deliveries.map((d) => _buildDeliveryTile(context, d)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTile(BuildContext context, Delivery delivery) {
    Color statusColor;
    String statusText;
    switch (delivery.status) {
      case DeliveryStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case DeliveryStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case DeliveryStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return ListTile(
      title: Text('Delivery #${delivery.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat.yMMMd().format(delivery.deliveryDate)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('৳${delivery.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DeliveryDetailScreen(delivery: delivery)),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShopFormScreen(shop: widget.shop)),
    ).then((_) => _refreshData());
  }

  void _createDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryFormScreen(preSelectedShop: widget.shop)),
    ).then((_) => _refreshData());
  }
}
