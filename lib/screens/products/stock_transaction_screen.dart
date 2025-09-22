import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/stock_transaction.dart';
import '../../providers/stock_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Stock Entry'),
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
              _buildStep(1, 'Select Transaction Type'),
              _buildTypeSelection(),
              const SizedBox(height: 24),
              _buildStep(2, 'Enter Details'),
              _buildDetailsCard(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
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
                  'Current Stock: ${stock.toStringAsFixed(1)} ${widget.product.unit}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTypeTile(StockTransactionType.stockIn, 'Stock In', 'Add new items to inventory.', Icons.add_circle, Colors.green),
            _buildTypeTile(StockTransactionType.stockOut, 'Stock Out', 'Remove items from inventory (e.g., sold, used). ', Icons.remove_circle, Colors.red),
            _buildTypeTile(StockTransactionType.adjustment, 'Adjustment', 'Correct the inventory count (e.g., damaged goods). ', Icons.edit, Colors.blue),
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

  Widget _buildDetailsCard() {
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
                labelText: 'Quantity (${widget.product.unit})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter a quantity';
                final quantity = double.tryParse(value);
                if (quantity == null || quantity <= 0) return 'Please enter a valid quantity';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference (Optional)',
                hintText: 'e.g., PO #123, Damaged goods',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
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
        label: const Text('Save Transaction', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
