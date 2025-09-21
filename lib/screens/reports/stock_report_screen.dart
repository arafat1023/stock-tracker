import 'package:flutter/material.dart';
import '../../services/report_service.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final ReportService _reportService = ReportService();
  List<StockBalanceItem> _stockItems = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // name, stock, value
  bool _sortAscending = true;
  StockStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadStockReport();
  }

  Future<void> _loadStockReport() async {
    setState(() => _isLoading = true);
    try {
      final items = await _reportService.getStockBalanceReport();
      setState(() {
        _stockItems = items;
        _isLoading = false;
        _applySortAndFilter();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stock report: $e')),
        );
      }
    }
  }

  void _applySortAndFilter() {
    var items = List<StockBalanceItem>.from(_stockItems);

    // Apply filter
    if (_filterStatus != null) {
      items = items.where((item) => item.status == _filterStatus).toList();
    }

    // Apply sort
    items.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.product.name.compareTo(b.product.name);
          break;
        case 'stock':
          comparison = a.currentStock.compareTo(b.currentStock);
          break;
        case 'value':
          comparison = a.stockValue.compareTo(b.stockValue);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _stockItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Report'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleSortAction,
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(_sortBy == 'name' ? Icons.check : Icons.sort_by_alpha),
                    const SizedBox(width: 8),
                    const Text('Sort by Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stock',
                child: Row(
                  children: [
                    Icon(_sortBy == 'stock' ? Icons.check : Icons.format_list_numbered),
                    const SizedBox(width: 8),
                    const Text('Sort by Stock'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'value',
                child: Row(
                  children: [
                    Icon(_sortBy == 'value' ? Icons.check : Icons.attach_money),
                    const SizedBox(width: 8),
                    const Text('Sort by Value'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<StockStatus?>(
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
                _applySortAndFilter();
              });
            },
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(_filterStatus == null ? Icons.check : Icons.clear_all),
                    const SizedBox(width: 8),
                    const Text('All Items'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StockStatus.inStock,
                child: Row(
                  children: [
                    Icon(_filterStatus == StockStatus.inStock
                        ? Icons.check : Icons.check_circle,
                        color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('In Stock'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StockStatus.lowStock,
                child: Row(
                  children: [
                    Icon(_filterStatus == StockStatus.lowStock
                        ? Icons.check : Icons.warning,
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text('Low Stock'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StockStatus.outOfStock,
                child: Row(
                  children: [
                    Icon(_filterStatus == StockStatus.outOfStock
                        ? Icons.check : Icons.error,
                        color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Out of Stock'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStockReport,
              child: Column(
                children: [
                  if (_filterStatus != null) _buildFilterChip(),
                  _buildSummaryCard(),
                  Expanded(
                    child: _stockItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No stock items found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _stockItems.length,
                            itemBuilder: (context, index) {
                              final item = _stockItems[index];
                              return _buildStockItemTile(item);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip() {
    String filterText;
    Color filterColor;

    switch (_filterStatus!) {
      case StockStatus.inStock:
        filterText = 'In Stock';
        filterColor = Colors.green;
        break;
      case StockStatus.lowStock:
        filterText = 'Low Stock';
        filterColor = Colors.orange;
        break;
      case StockStatus.outOfStock:
        filterText = 'Out of Stock';
        filterColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Chip(
        label: Text(filterText),
        backgroundColor: filterColor.withValues(alpha: 0.1),
        side: BorderSide(color: filterColor),
        onDeleted: () {
          setState(() {
            _filterStatus = null;
            _applySortAndFilter();
          });
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalItems = _stockItems.length;
    final totalValue = _stockItems.fold(0.0, (sum, item) => sum + item.stockValue);
    final lowStockCount = _stockItems.where((item) => item.status == StockStatus.lowStock).length;
    final outOfStockCount = _stockItems.where((item) => item.status == StockStatus.outOfStock).length;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Items',
                    totalItems.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Value',
                    '\$${totalValue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Low Stock',
                    lowStockCount.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Out of Stock',
                    outOfStockCount.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemTile(StockBalanceItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case StockStatus.inStock:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case StockStatus.lowStock:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case StockStatus.outOfStock:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          item.product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unit: ${item.product.unit}'),
            Text('Price: \$${item.product.price.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.currentStock.toStringAsFixed(1)} ${item.product.unit}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text(
              '\$${item.stockValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSortAction(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _applySortAndFilter();
    });
  }
}