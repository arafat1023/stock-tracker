import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/shop.dart';
import '../../models/delivery.dart';
import '../../providers/delivery_provider.dart';
import 'shop_form_screen.dart';
import '../deliveries/delivery_form_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadDeliveries(shopId: widget.shop.id);
    });
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
          ),
        ],
      ),
      body: SingleChildScrollView(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDelivery(context),
        label: const Text('Create Delivery'),
        icon: const Icon(Icons.local_shipping),
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
            _buildInfoRow('Name', widget.shop.name),
            _buildInfoRow('Address', widget.shop.address),
            if (widget.shop.contact.isNotEmpty)
              _buildInfoRow('Contact', widget.shop.contact),
            _buildInfoRow('Created', DateFormat('MMM dd, yyyy').format(widget.shop.createdAt)),
            _buildInfoRow('Updated', DateFormat('MMM dd, yyyy').format(widget.shop.updatedAt)),
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

  Widget _buildDeliveryStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Consumer<DeliveryProvider>(
              builder: (context, deliveryProvider, child) {
                final shopDeliveries = deliveryProvider.deliveries
                    .where((d) => d.shopId == widget.shop.id)
                    .toList();

                final totalDeliveries = shopDeliveries.length;
                final completedDeliveries = shopDeliveries
                    .where((d) => d.status == DeliveryStatus.completed)
                    .length;
                final pendingDeliveries = shopDeliveries
                    .where((d) => d.status == DeliveryStatus.pending)
                    .length;
                final totalAmount = shopDeliveries
                    .where((d) => d.status == DeliveryStatus.completed)
                    .fold(0.0, (sum, d) => sum + d.totalAmount);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Deliveries',
                            totalDeliveries.toString(),
                            Icons.local_shipping,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            completedDeliveries.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            pendingDeliveries.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Total Value',
                            '\$${totalAmount.toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.purple,
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildRecentDeliveries() {
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
                  'Recent Deliveries',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full delivery history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<DeliveryProvider>(
              builder: (context, deliveryProvider, child) {
                final shopDeliveries = deliveryProvider.deliveries
                    .where((d) => d.shopId == widget.shop.id)
                    .take(5)
                    .toList();

                if (shopDeliveries.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No deliveries found\nCreate your first delivery',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: shopDeliveries.map((delivery) {
                    return _buildDeliveryTile(delivery);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTile(Delivery delivery) {
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

    return ListTile(
      leading: Icon(statusIcon, color: statusColor),
      title: Text('Delivery #${delivery.id}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${delivery.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            delivery.status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to delivery detail
      },
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopFormScreen(shop: widget.shop),
      ),
    );
  }

  void _createDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryFormScreen(preSelectedShop: widget.shop),
      ),
    );
  }
}