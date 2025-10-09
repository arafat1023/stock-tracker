import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/shop.dart';
import '../../utils/app_strings.dart';

class ShopFormScreen extends StatefulWidget {
  final Shop? shop;

  const ShopFormScreen({super.key, this.shop});

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  bool get isEditing => widget.shop != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.shop!.name;
      _addressController.text = widget.shop!.address;
      _contactController.text = widget.shop!.contact;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? AppStrings.editShop(isBengali) : AppStrings.addNewShop(isBengali)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.shopDetails(isBengali),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the information for the new shop.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.shopName(isBengali),
                      hintText: AppStrings.shopNameHint(isBengali),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.pleaseEnterShopName(isBengali);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: AppStrings.address(isBengali),
                      hintText: AppStrings.addressHint(isBengali),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.pleaseEnterAddress(isBengali);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: AppStrings.contact(isBengali),
                      hintText: AppStrings.phoneHint(isBengali),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.contact_phone),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(
                        isEditing ? AppStrings.save(isBengali) : AppStrings.addShop(isBengali),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  void _saveShop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture context-dependent objects before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final now = DateTime.now();
      final shop = Shop(
        id: isEditing ? widget.shop!.id : null,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contact: _contactController.text.trim(),
        createdAt: isEditing ? widget.shop!.createdAt : now,
        updatedAt: now,
      );

      final provider = context.read<ShopProvider>();
      if (isEditing) {
        await provider.updateShop(shop);
      } else {
        await provider.addShop(shop);
      }

      if (mounted) {
        navigator.pop(true); // Return true to indicate success
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Shop ${isEditing ? 'updated' : 'added'} successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error saving shop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
