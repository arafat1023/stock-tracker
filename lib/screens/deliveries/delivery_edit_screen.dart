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
import '../../models/delivery.dart';
import '../../models/delivery_item.dart';

class DeliveryEditScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryEditScreen({super.key, required this.delivery});

  @override
  State<DeliveryEditScreen> createState() => _DeliveryEditScreenState();
}

class _DeliveryEditScreenState extends State<DeliveryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  Shop? _selectedShop;
  DateTime _selectedDate = DateTime.now();
  final List<DeliveryItemForm> _deliveryItems = [];
  final Map<int, double> _availableStock = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.delivery.deliveryDate;
    _notesController.text = widget.delivery.notes;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeliveryData();
    });
  }

  Future<void> _loadDeliveryData() async {
    final shopProvider = context.read<ShopProvider>();
    final productProvider = context.read<ProductProvider>();
    final deliveryProvider = context.read<DeliveryProvider>();

    await shopProvider.loadShops();
    await productProvider.loadProducts();

    if (!mounted) return;

    // Get the shop
    _selectedShop = shopProvider.getShopById(widget.delivery.shopId);

    // Load existing delivery items
    final items = await deliveryProvider.getDeliveryItems(widget.delivery.id!);

    // Collect all product IDs for batch stock fetching
    final productIds = items.map((item) => item.productId).toList();

    // Fetch all stock data in a single batch call
    final stockMap = await _databaseService.getAvailableStockForProducts(productIds);

    // Build the delivery items list
    final tempDeliveryItems = <DeliveryItemForm>[];
    final tempAvailableStock = <int, double>{};

    for (final item in items) {
      final product = productProvider.getProductById(item.productId);
      if (product != null) {
        // Calculate available stock (current stock + this item's quantity since it will be returned during edit)
        final currentAvailable = stockMap[product.id!] ?? 0.0;
        final totalAvailable = currentAvailable + item.quantity;

        tempAvailableStock[product.id!] = totalAvailable;
        tempDeliveryItems.add(DeliveryItemForm(
          product: product,
          quantityController: TextEditingController(text: item.quantity.toString()),
          priceController: TextEditingController(text: item.unitPrice.toString()),
          totalPrice: item.totalPrice,
        ));
      }
    }

    // Update state only once
    if (mounted) {
      setState(() {
        _availableStock.addAll(tempAvailableStock);
        _deliveryItems.addAll(tempDeliveryItems);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text('${AppStrings.edit(isBengali)} ${AppStrings.delivery(isBengali)} #${widget.delivery.id}'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
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
                            _buildStep(2, 'Edit Products'),
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final qty = double.tryParse(v);
                    if (qty == null || qty <= 0) return 'Invalid quantity';
                    if (qty > availableStock) return 'Exceeds stock (${availableStock.toStringAsFixed(1)})';
                    return null;
                  },
                  onChanged: (_) => _calculateItemTotal(item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.priceController,
                  decoration: const InputDecoration(labelText: 'Unit Price', prefixText: '৳', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Invalid' : null,
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
    bool canSave = !_isSubmitting && _selectedShop != null && _deliveryItems.isNotEmpty && _formKey.currentState?.validate() == true;

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
            onPressed: canSave ? _updateDelivery : null,
            icon: const Icon(Icons.check),
            label: const Text('Update Delivery'),
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
    if (!mounted) return;

    // Don't allow adding products with zero stock
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add "${product.name}" - No stock available (current stock: ${stock.toStringAsFixed(1)} ${product.unit})'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _availableStock[product.id!] = stock;
      _deliveryItems.add(DeliveryItemForm(
        product: product,
        quantityController: TextEditingController(text: '1'),
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

  void _updateDelivery() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    // Capture context-dependent references before async gaps
    final deliveryProvider = context.read<DeliveryProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final items = _deliveryItems.map((item) {
        final quantity = double.parse(item.quantityController.text);
        final unitPrice = double.parse(item.priceController.text);
        return DeliveryItem(
          deliveryId: widget.delivery.id!,
          productId: item.product!.id!,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: quantity * unitPrice, // Calculate fresh from current values
        );
      }).toList();

      await deliveryProvider.editDelivery(
        deliveryId: widget.delivery.id!,
        shopId: _selectedShop!.id!,
        deliveryDate: _selectedDate,
        items: items,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        navigator.pop(true);
        messenger.showSnackBar(const SnackBar(content: Text('Delivery updated successfully.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
