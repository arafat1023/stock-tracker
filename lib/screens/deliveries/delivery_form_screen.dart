import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_strings.dart';
import '../../widgets/searchable_shop_selector.dart';
import '../../widgets/searchable_product_dialog.dart';
import '../../services/database_service.dart';

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
  final DatabaseService _databaseService = DatabaseService();

  Shop? _selectedShop;
  DateTime _selectedDate = DateTime.now();
  final List<DeliveryItemForm> _deliveryItems = [];
  final Map<int, double> _availableStock = {};

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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.createDelivery(isBengali)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStep(1, 'Delivery Details'),
                  _buildDeliveryInfoCard(),
                  const SizedBox(height: 24),
                  _buildStep(2, 'Add Products'),
                  _buildProductsCard(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildStep(int step, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          CircleAvatar(radius: 14, child: Text('$step')),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                return SearchableShopSelector(
                  shops: shopProvider.shops,
                  selectedShop: _selectedShop,
                  onChanged: (shop) => setState(() => _selectedShop = shop),
                  labelText: 'Shop',
                  hintText: 'Search and select a shop',
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(
                labelText: 'Delivery Date',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixText: DateFormat.yMMMd().format(_selectedDate),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_deliveryItems.isEmpty)
              const Center(child: Text('No products added yet.', style: TextStyle(color: Colors.grey)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _deliveryItems.length,
                itemBuilder: (context, index) => _buildProductItem(_deliveryItems[index], index),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(DeliveryItemForm item, int index) {
    final productId = item.product?.id;
    final availableStock = productId != null ? (_availableStock[productId] ?? 0.0) : 0.0;
    final currentQuantity = double.tryParse(item.quantityController.text) ?? 0.0;
    final isOverStock = currentQuantity > availableStock;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.product?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(onPressed: () => _removeProduct(index), icon: const Icon(Icons.delete, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                availableStock > 10 ? Icons.check_circle : availableStock > 0 ? Icons.warning : Icons.cancel,
                size: 16,
                color: availableStock > 10 ? Colors.green : availableStock > 0 ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                'Available: ${availableStock.toStringAsFixed(1)} ${item.product?.unit}',
                style: TextStyle(
                  fontSize: 12,
                  color: availableStock > 10 ? Colors.green : availableStock > 0 ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.quantityController,
                  decoration: InputDecoration(
                    labelText: 'Qty (${item.product?.unit})',
                    border: const OutlineInputBorder(),
                    suffixText: 'Max: ${availableStock.toStringAsFixed(1)}',
                    suffixStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                    errorText: isOverStock ? 'Exceeds available stock' : null,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final qty = double.tryParse(v);
                    if (qty == null || qty <= 0) return 'Invalid quantity';
                    if (qty > availableStock) return 'Exceeds stock (${availableStock.toStringAsFixed(1)})';
                    return null;
                  },
                  onChanged: (_) {
                    _calculateItemTotal(item);
                    setState(() {}); // Refresh validation
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.priceController,
                  decoration: const InputDecoration(labelText: 'Unit Price', prefixText: '৳', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) < 0) ? 'Invalid' : null,
                  onChanged: (_) => _calculateItemTotal(item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Total: ৳${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    double totalAmount = _deliveryItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    bool canSave = _selectedShop != null && _deliveryItems.isNotEmpty && _formKey.currentState?.validate() == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, -4))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Amount', style: TextStyle(color: Colors.grey)),
              Text('৳${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: canSave ? _createDelivery : null,
            icon: const Icon(Icons.check),
            label: const Text('Create Delivery'),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (date != null) setState(() => _selectedDate = date);
  }

  void _addProduct() async {
    final products = context.read<ProductProvider>().products;
    final availableProducts = products.where((p) => !_deliveryItems.any((item) => item.product?.id == p.id)).toList();

    final Product? selectedProduct = await showDialog<Product>(
      context: context,
      builder: (context) => SearchableProductDialog(
        products: availableProducts,
        title: 'Select a Product',
      ),
    );

    if (selectedProduct != null) {
      _addProductToDelivery(selectedProduct);
    }
  }

  void _addProductToDelivery(Product product) async {
    final stock = await _databaseService.getAvailableStock(product.id!);
    setState(() {
      _availableStock[product.id!] = stock;
      _deliveryItems.add(DeliveryItemForm(
        product: product,
        quantityController: TextEditingController(text: stock > 0 ? '1' : '0'),
        priceController: TextEditingController(text: product.price.toString()),
      ));
      _calculateItemTotal(_deliveryItems.last);
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
    setState(() => item.totalPrice = quantity * price);
  }

  void _createDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final items = _deliveryItems.map((item) {
        return DeliveryItem(
          deliveryId: 0,
          productId: item.product!.id!,
          quantity: double.parse(item.quantityController.text),
          unitPrice: double.parse(item.priceController.text),
          totalPrice: item.totalPrice,
        );
      }).toList();

      await context.read<DeliveryProvider>().createDelivery(
        shopId: _selectedShop!.id!,
        deliveryDate: _selectedDate,
        items: items,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery created successfully.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
