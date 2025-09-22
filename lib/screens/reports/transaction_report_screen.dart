import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/delivery.dart';

class TransactionReportScreen extends StatefulWidget {
  const TransactionReportScreen({super.key});

  @override
  State<TransactionReportScreen> createState() => _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<TransactionRecord> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _getTransactionRecords();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  Future<List<TransactionRecord>> _getTransactionRecords() async {
    final List<TransactionRecord> records = [];

    // Get stock transactions (additions/adjustments)
    final stockTransactions = await _databaseService.getStockTransactions();
    for (final transaction in stockTransactions) {
      final product = await _databaseService.getProduct(transaction.productId);
      if (product != null) {
        records.add(TransactionRecord(
          id: 'stock_${transaction.id}',
          type: transaction.quantity > 0 ? 'Stock In' : 'Stock Out',
          productName: product.name,
          quantity: transaction.quantity.abs().toInt(),
          date: transaction.date,
          shopName: null,
          notes: transaction.reference,
        ));
      }
    }

    // Get delivery transactions (outgoing)
    final deliveries = await _databaseService.getDeliveries();
    for (final delivery in deliveries) {
      if (delivery.status == DeliveryStatus.completed) {
        final shop = await _databaseService.getShop(delivery.shopId);
        final items = await _databaseService.getDeliveryItems(delivery.id!);
        for (final item in items) {
          final product = await _databaseService.getProduct(item.productId);
          if (product != null && shop != null) {
            records.add(TransactionRecord(
              id: 'delivery_${delivery.id}_${item.productId}',
              type: 'Delivery',
              productName: product.name,
              quantity: item.quantity.toInt(),
              date: delivery.deliveryDate,
              shopName: shop.name,
              notes: 'Delivered to ${shop.name}',
            ));
          }
        }
      }
    }

    // Sort by date (newest first)
    records.sort((a, b) => b.date.compareTo(a.date));

    return records;
  }

  List<TransactionRecord> get _filteredTransactions {
    var filtered = _transactions;

    // Filter by type
    if (_selectedFilter != 'All') {
      filtered = filtered.where((t) => t.type == _selectedFilter).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', 'Stock In', 'Stock Out', 'Delivery']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range),
                              label: Text(_dateRange == null
                                  ? 'Select Date Range'
                                  : 'Date Range Selected'),
                            ),
                          ),
                          if (_dateRange != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _clearDateFilter,
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_dateRange != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'From: ${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} '
                      'To: ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),

          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total In',
                    _filteredTransactions
                        .where((t) => t.type == 'Stock In')
                        .fold(0, (sum, t) => sum + t.quantity),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Out',
                    _filteredTransactions
                        .where((t) => t.type == 'Stock Out' || t.type == 'Delivery')
                        .fold(0, (sum, t) => sum + t.quantity),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Deliveries',
                    _filteredTransactions
                        .where((t) => t.type == 'Delivery')
                        .length,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          return _buildTransactionTile(transaction);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionRecord transaction) {
    IconData icon;
    Color color;

    switch (transaction.type) {
      case 'Stock In':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'Stock Out':
        icon = Icons.remove_circle;
        color = Colors.red;
        break;
      case 'Delivery':
        icon = Icons.local_shipping;
        color = Colors.blue;
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${transaction.type}: ${transaction.quantity} pieces',
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (transaction.shopName != null)
              Text('Shop: ${transaction.shopName}'),
            if (transaction.notes.isNotEmpty)
              Text(
                transaction.notes,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionRecord {
  final String id;
  final String type;
  final String productName;
  final int quantity;
  final DateTime date;
  final String? shopName;
  final String notes;

  TransactionRecord({
    required this.id,
    required this.type,
    required this.productName,
    required this.quantity,
    required this.date,
    this.shopName,
    required this.notes,
  });
}