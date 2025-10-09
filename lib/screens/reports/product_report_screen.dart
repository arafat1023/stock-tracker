import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';

class ProductReportScreen extends StatefulWidget {
  const ProductReportScreen({super.key});

  @override
  State<ProductReportScreen> createState() => _ProductReportScreenState();
}

class _ProductReportScreenState extends State<ProductReportScreen> {
  final ReportService _reportService = ReportService();
  List<ProductPerformanceItem> _productItems = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'revenue'; // revenue, quantity, deliveries
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadProductReport();
  }

  Future<void> _loadProductReport() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final items = await _reportService.getProductPerformanceReport(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _productItems = items;
        _isLoading = false;
        _applySorting();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error loading product report: $e')),
        );
      }
    }
  }

  void _applySorting() {
    _productItems.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'revenue':
          comparison = a.totalRevenue.compareTo(b.totalRevenue);
          break;
        case 'quantity':
          comparison = a.totalQuantityDelivered.compareTo(b.totalQuantityDelivered);
          break;
        case 'deliveries':
          comparison = a.deliveryCount.compareTo(b.deliveryCount);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Best-Selling Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
          ),
          PopupMenuButton<String>(
            onSelected: _handleSortAction,
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Products',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'revenue',
                child: Text('Sort by Total Sales', style: TextStyle(fontWeight: _sortBy == 'revenue' ? FontWeight.bold : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Text('Sort by Quantity Sold', style: TextStyle(fontWeight: _sortBy == 'quantity' ? FontWeight.bold : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'deliveries',
                child: Text('Sort by Number of Deliveries', style: TextStyle(fontWeight: _sortBy == 'deliveries' ? FontWeight.bold : FontWeight.normal)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProductReport,
              child: Column(
                children: [
                  _buildDateRangeCard(),
                  _buildSummaryCard(),
                  Expanded(
                    child: _productItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No sales data found for this period.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _productItems.length,
                            itemBuilder: (context, index) {
                              final item = _productItems[index];
                              return _buildProductPerformanceCard(item, index + 1);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.date_range, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(onPressed: _showDateRangePicker, child: const Text('Change'))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalRevenue = _productItems.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final totalQuantity = _productItems.fold(0.0, (sum, item) => sum + item.totalQuantityDelivered);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Sales', '৳${totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
              _buildSummaryItem('Total Quantity Sold', totalQuantity.toStringAsFixed(1), Icons.shopping_cart, Colors.orange),
            ],
          ),
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

  Widget _buildProductPerformanceCard(ProductPerformanceItem item, int rank) {
    Color rankColor = rank <= 3 ? Colors.amber : Colors.grey.shade400;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: rankColor,
                  child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Sales', '৳${item.totalRevenue.toStringAsFixed(2)}'),
                _buildStatItem('Quantity Sold', '${item.totalQuantityDelivered.toStringAsFixed(1)} ${item.product.unit}'),
                _buildStatItem('Deliveries', item.deliveryCount.toString()),
              ],
            ),
          ],
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

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadProductReport();
    }
  }

  void _handleSortAction(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = false;
      }
      _applySorting();
    });
  }
}
