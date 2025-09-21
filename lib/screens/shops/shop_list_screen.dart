import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../models/shop.dart';
import 'shop_form_screen.dart';
import 'shop_detail_screen.dart';
import '../deliveries/delivery_form_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search shops...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<ShopProvider>().searchShops(value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          if (shopProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shopProvider.shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    shopProvider.searchQuery.isEmpty
                        ? 'No shops found.\nTap + to add your first shop.'
                        : 'No shops match your search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: shopProvider.shops.length,
            itemBuilder: (context, index) {
              final shop = shopProvider.shops[index];
              return ShopListTile(shop: shop);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddShop(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddShop(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShopFormScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ShopListTile extends StatelessWidget {
  final Shop shop;

  const ShopListTile({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            shop.name.isNotEmpty ? shop.name[0].toUpperCase() : 'S',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          shop.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shop.address.isNotEmpty)
              Text(
                shop.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (shop.contact.isNotEmpty)
              Text(
                'Contact: ${shop.contact}',
                style: const TextStyle(color: Colors.blue),
              ),
            Consumer<DeliveryProvider>(
              builder: (context, deliveryProvider, child) {
                final deliveryCount = deliveryProvider.deliveries
                    .where((d) => d.shopId == shop.id).length;
                return Text(
                  'Deliveries: $deliveryCount',
                  style: TextStyle(
                    color: deliveryCount > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, shop),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delivery',
              child: ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.blue),
                title: Text('Create Delivery', style: TextStyle(color: Colors.blue)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToShopDetail(context, shop),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Shop shop) {
    switch (action) {
      case 'view':
        _navigateToShopDetail(context, shop);
        break;
      case 'edit':
        _navigateToEditShop(context, shop);
        break;
      case 'delivery':
        _createDelivery(context, shop);
        break;
      case 'delete':
        _showDeleteConfirmation(context, shop);
        break;
    }
  }

  void _navigateToShopDetail(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailScreen(shop: shop),
      ),
    );
  }

  void _navigateToEditShop(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopFormScreen(shop: shop),
      ),
    );
  }

  void _createDelivery(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryFormScreen(preSelectedShop: shop),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Shop shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete "${shop.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShop(context, shop);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteShop(BuildContext context, Shop shop) async {
    try {
      await context.read<ShopProvider>().deleteShop(shop.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${shop.name} deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting shop: $e')),
        );
      }
    }
  }
}