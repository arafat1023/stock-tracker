import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/delivery_item.dart';

class DeliveryFormScreen extends StatefulWidget {
  final Shop? preSelectedShop;

  const DeliveryFormScreen({super.key, this.preSelectedShop});

  @override
  State<DeliveryFormScreen> createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends State<DeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  Shop? _selectedShop;
  DateTime _selectedDate = DateTime.now();
  final List<DeliveryItemForm> _deliveryItems = [];

  @override
  void initState() {
    super.initState();
    _selectedShop = widget.preSelectedShop;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadShops();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Delivery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDeliveryInfoCard(),
                    const SizedBox(height: 16),
                    _buildProductsCard(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
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
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                return DropdownButtonFormField<Shop>(
                  value: _selectedShop,
                  decoration: const InputDecoration(
                    labelText: 'Select Shop *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                  items: shopProvider.shops.map((shop) {
                    return DropdownMenuItem(
                      value: shop,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.name),
                          Text(
                            shop.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (shop) {
                    setState(() {
                      _selectedShop = shop;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a shop';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Delivery Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
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
                  'Products',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_deliveryItems.isEmpty)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No products added yet.\nTap "Add Product" to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _deliveryItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  DeliveryItemForm item = entry.value;
                  return _buildProductItem(item, index);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(DeliveryItemForm item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product?.name ?? 'Select Product',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeProduct(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            if (item.product != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: item.quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity (${item.product!.unit})',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Enter valid quantity';
                        }
                        return null;
                      },
                      onChanged: (value) => _calculateItemTotal(item),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: item.priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                      onChanged: (value) => _calculateItemTotal(item),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<double>(
                    future: context.read<StockProvider>().getProductStockBalance(item.product!.id!),
                    builder: (context, snapshot) {
                      final stock = snapshot.data ?? 0.0;
                      return Text(
                        'Available Stock: ${stock.toStringAsFixed(1)} ${item.product!.unit}',
                        style: TextStyle(
                          color: stock > 0 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Total: \$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    double totalAmount = _deliveryItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _deliveryItems.isNotEmpty ? _createDelivery : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create Delivery',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return AlertDialog(
            title: const Text('Select Product'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: productProvider.products.length,
                itemBuilder: (context, index) {
                  final product = productProvider.products[index];
                  final isAlreadyAdded = _deliveryItems.any((item) => item.product?.id == product.id);

                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('${product.unit} - \$${product.price.toStringAsFixed(2)}'),
                    enabled: !isAlreadyAdded,
                    onTap: isAlreadyAdded ? null : () {
                      _addProductToDelivery(product);
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

  void _addProductToDelivery(Product product) {
    setState(() {
      _deliveryItems.add(DeliveryItemForm(
        product: product,
        quantityController: TextEditingController(),
        priceController: TextEditingController(text: product.price.toString()),
      ));
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _deliveryItems[index].dispose();
      _deliveryItems.removeAt(index);
    });
  }

  void _calculateItemTotal(DeliveryItemForm item) {
    final quantity = double.tryParse(item.quantityController.text) ?? 0.0;
    final price = double.tryParse(item.priceController.text) ?? 0.0;
    setState(() {
      item.totalPrice = quantity * price;
    });
  }

  void _createDelivery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop')),
      );
      return;
    }

    if (_deliveryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    try {
      final deliveryItems = _deliveryItems.map((item) {
        final quantity = double.parse(item.quantityController.text);
        final unitPrice = double.parse(item.priceController.text);
        return DeliveryItem(
          deliveryId: 0, // Will be set by the provider
          productId: item.product!.id!,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: quantity * unitPrice,
        );
      }).toList();

      await context.read<DeliveryProvider>().createDelivery(
        shopId: _selectedShop!.id!,
        deliveryDate: _selectedDate,
        items: deliveryItems,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _deliveryItems) {
      item.dispose();
    }
    super.dispose();
  }
}

class DeliveryItemForm {
  final Product? product;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  double totalPrice;

  DeliveryItemForm({
    this.product,
    required this.quantityController,
    required this.priceController,
    this.totalPrice = 0.0,
  });

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}