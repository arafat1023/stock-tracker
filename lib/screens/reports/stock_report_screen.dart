import 'package:flutter/material.dart';
import '../../services/report_service.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final ReportService _reportService = ReportService();
  List<StockBalanceItem> _originalStockItems = [];
  List<StockBalanceItem> _filteredStockItems = [];
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final items = await _reportService.getStockBalanceReport();
      setState(() {
        _originalStockItems = items;
        _applySortAndFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error loading stock report: $e')),
        );
      }
    }
  }

  void _applySortAndFilter() {
    var items = List<StockBalanceItem>.from(_originalStockItems);

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
      _filteredStockItems = items;
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
            tooltip: 'Sort Products',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name', style: TextStyle(fontWeight: _sortBy == 'name' ? FontWeight.bold : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'stock',
                child: Text('Sort by Stock Level', style: TextStyle(fontWeight: _sortBy == 'stock' ? FontWeight.bold : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'value',
                child: Text('Sort by Stock Value', style: TextStyle(fontWeight: _sortBy == 'value' ? FontWeight.bold : FontWeight.normal)),
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
                  _buildSummaryCard(),
                  _buildFilterChips(),
                  Expanded(
                    child: _filteredStockItems.isEmpty
                        ? Center(
                            child: Text(
                              _filterStatus == null
                                  ? 'You don\'t have any products yet.'
                                  : 'No products match this filter.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredStockItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredStockItems[index];
                              return _buildStockItemCard(item);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalValue = _originalStockItems.fold(0.0, (sum, item) => sum + item.stockValue);
    final lowStockCount = _originalStockItems.where((item) => item.status == StockStatus.lowStock).length;
    final outOfStockCount = _originalStockItems.where((item) => item.status == StockStatus.outOfStock).length;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Value', '৳${totalValue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                _buildSummaryItem('Low Stock', lowStockCount.toString(), Icons.warning, Colors.orange),
                _buildSummaryItem('Out of Stock', outOfStockCount.toString(), Icons.error, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterStatus == null,
            onSelected: (selected) {
              setState(() {
                _filterStatus = null;
                _applySortAndFilter();
              });
            },
          ),
          FilterChip(
            label: const Text('In Stock'),
            selected: _filterStatus == StockStatus.inStock,
            onSelected: (selected) {
              setState(() {
                _filterStatus = StockStatus.inStock;
                _applySortAndFilter();
              });
            },
            selectedColor: Colors.green.withValues(alpha: 0.2),
          ),
          FilterChip(
            label: const Text('Low Stock'),
            selected: _filterStatus == StockStatus.lowStock,
            onSelected: (selected) {
              setState(() {
                _filterStatus = StockStatus.lowStock;
                _applySortAndFilter();
              });
            },
            selectedColor: Colors.orange.withValues(alpha: 0.2),
          ),
          FilterChip(
            label: const Text('Out of Stock'),
            selected: _filterStatus == StockStatus.outOfStock,
            onSelected: (selected) {
              setState(() {
                _filterStatus = StockStatus.outOfStock;
                _applySortAndFilter();
              });
            },
            selectedColor: Colors.red.withAlpha(51),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemCard(StockBalanceItem item) {
    Color statusColor;

    switch (item.status) {
      case StockStatus.inStock:
        statusColor = Colors.green;
        break;
      case StockStatus.lowStock:
        statusColor = Colors.orange;
        break;
      case StockStatus.outOfStock:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 10,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Price: ৳${item.product.price.toStringAsFixed(2)} per ${item.product.unit}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Level', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '${item.currentStock.toStringAsFixed(1)} ${item.product.unit}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Stock Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '৳${item.stockValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
