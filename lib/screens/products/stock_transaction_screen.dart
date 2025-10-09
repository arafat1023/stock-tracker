import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/stock_transaction.dart';
import '../../providers/stock_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_strings.dart';

class StockTransactionScreen extends StatefulWidget {
  final Product product;

  const StockTransactionScreen({super.key, required this.product});

  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();

  StockTransactionType _selectedType = StockTransactionType.stockIn;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.stockTransactions(isBengali)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentStockCard(),
              const SizedBox(height: 24),
              _buildStep(1, AppStrings.transactionType(isBengali)),
              _buildTypeSelection(isBengali),
              const SizedBox(height: 24),
              _buildStep(2, AppStrings.productDetails(isBengali)),
              _buildDetailsCard(isBengali),
              const SizedBox(height: 32),
              _buildSaveButton(isBengali),
            ],
          ),
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

  Widget _buildCurrentStockCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product: ${widget.product.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<double>(
              future: context.read<StockProvider>().getProductStockBalance(widget.product.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stock = snapshot.data ?? 0.0;
                return Text(
                  '${AppStrings.currentStock(context.read<LanguageProvider>().isBengali)}: ${stock.toStringAsFixed(1)} ${widget.product.unit}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection(bool isBengali) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTypeTile(StockTransactionType.stockIn, AppStrings.stockIn(isBengali), 'Add new items to inventory.', Icons.add_circle, Colors.green),
            _buildTypeTile(StockTransactionType.stockOut, AppStrings.stockOut(isBengali), 'Remove items from inventory (e.g., sold, used).', Icons.remove_circle, Colors.red),
            _buildTypeTile(StockTransactionType.adjustment, AppStrings.adjustment(isBengali), 'Correct inventory during audit. Use + to add, - to remove (e.g., +5 found, -3 damaged).', Icons.edit, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTile(StockTransactionType type, String title, String subtitle, IconData icon, Color color) {
    return RadioListTile<StockTransactionType>(
      value: type,
      groupValue: _selectedType,
      onChanged: (value) => setState(() => _selectedType = value!),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildDetailsCard(bool isBengali) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: '${AppStrings.quantity(isBengali)} (${widget.product.unit})',
                hintText: _selectedType == StockTransactionType.adjustment ? 'e.g., 10 or -5' : 'e.g., 10',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return AppStrings.pleaseEnterQuantity(isBengali);
                final quantity = double.tryParse(value);
                if (quantity == null) return AppStrings.pleaseEnterValidQuantity(isBengali);

                // For adjustments, allow negative values; for stockIn/stockOut, require positive
                if (_selectedType != StockTransactionType.adjustment && quantity <= 0) {
                  return AppStrings.pleaseEnterValidQuantity(isBengali);
                }

                // For adjustments, don't allow zero (meaningless adjustment)
                if (_selectedType == StockTransactionType.adjustment && quantity == 0) {
                  return 'Adjustment cannot be zero';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: AppStrings.notes(isBengali),
                hintText: AppStrings.notesHint(isBengali),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isBengali) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.save),
        label: Text(AppStrings.save(isBengali), style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    // Capture context-dependent objects before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final quantity = double.parse(_quantityController.text);
      final reference = _referenceController.text.trim().isEmpty ? 'Manual ${_selectedType.name}' : _referenceController.text.trim();

      await context.read<StockProvider>().addStockTransaction(
        productId: widget.product.id!,
        type: _selectedType,
        quantity: quantity,
        reference: reference,
      );

      if (mounted) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Stock updated successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
