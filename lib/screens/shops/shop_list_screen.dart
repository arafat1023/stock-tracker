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
      context.read<DeliveryProvider>().loadDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by shop name or address...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                context.read<ShopProvider>().searchShops(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                if (shopProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (shopProvider.shops.isEmpty) {
                  return _buildEmptyState(context, shopProvider.searchQuery.isNotEmpty);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: shopProvider.shops.length,
                  itemBuilder: (context, index) {
                    final shop = shopProvider.shops[index];
                    return ShopCard(shop: shop);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "shops_fab",
        onPressed: () => _navigateToAddShop(context),
        label: const Text('Add Shop'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.store_mall_directory_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No Shops Found' : 'You Have No Shops',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No shops match your search query.'
                : 'Tap the "Add Shop" button to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _navigateToAddShop(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShopFormScreen(),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<ShopProvider>().loadShops();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ShopCard extends StatelessWidget {
  final Shop shop;

  const ShopCard({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToShopDetail(context, shop),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary.withAlpha(25),
                    child: Icon(Icons.store, color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      shop.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.local_shipping, color: Colors.blue, size: 20),
                    label: const Text('Deliver', style: TextStyle(color: Colors.blue)),
                    onPressed: () => _createDelivery(context, shop),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (shop.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(shop.address, style: const TextStyle(color: Colors.grey))),
                    ],
                  ),
                ),
              if (shop.contact.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(shop.contact, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<DeliveryProvider>(
                    builder: (context, deliveryProvider, child) {
                      final deliveryCount = deliveryProvider.deliveries.where((d) => d.shopId == shop.id).length;
                      return _buildStatItem('Total Deliveries', deliveryCount.toString());
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToEditShop(context, shop),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, shop),
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

  Widget _buildStatItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
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
    ).then((_) {
      if (context.mounted) {
        context.read<ShopProvider>().loadShops();
      }
    });
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
        content: Text('Are you sure you want to delete "${shop.name}"? This will also delete all associated deliveries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
          SnackBar(content: Text('"${shop.name}" was deleted.')),
        );
        context.read<ShopProvider>().loadShops();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting shop: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
