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
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadProductReport();
  }

  Future<void> _loadProductReport() async {
    setState(() => _isLoading = true);
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
        ScaffoldMessenger.of(context).showSnackBar(
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
        title: const Text('Product Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
          ),
          PopupMenuButton<String>(
            onSelected: _handleSortAction,
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'revenue',
                child: Row(
                  children: [
                    Icon(_sortBy == 'revenue' ? Icons.check : Icons.attach_money),
                    const SizedBox(width: 8),
                    const Text('Sort by Revenue'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: [
                    Icon(_sortBy == 'quantity' ? Icons.check : Icons.straighten),
                    const SizedBox(width: 8),
                    const Text('Sort by Quantity'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'deliveries',
                child: Row(
                  children: [
                    Icon(_sortBy == 'deliveries' ? Icons.check : Icons.local_shipping),
                    const SizedBox(width: 8),
                    const Text('Sort by Deliveries'),
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
              onRefresh: _loadProductReport,
              child: Column(
                children: [
                  _buildDateRangeCard(),
                  _buildSummaryCard(),
                  Expanded(
                    child: _productItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No product data found for selected period',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _productItems.length,
                            itemBuilder: (context, index) {
                              final item = _productItems[index];
                              return _buildProductPerformanceTile(item, index + 1);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Period: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: _showDateRangePicker,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalProducts = _productItems.length;
    final totalRevenue = _productItems.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final totalQuantity = _productItems.fold(0.0, (sum, item) => sum + item.totalQuantityDelivered);
    final totalDeliveries = _productItems.fold(0, (sum, item) => sum + item.deliveryCount);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Products Sold',
                    totalProducts.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Revenue',
                    '\$${totalRevenue.toStringAsFixed(2)}',
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
                    'Total Quantity',
                    totalQuantity.toStringAsFixed(1),
                    Icons.straighten,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Deliveries',
                    totalDeliveries.toString(),
                    Icons.local_shipping,
                    Colors.purple,
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

  Widget _buildProductPerformanceTile(ProductPerformanceItem item, int rank) {
    Color rankColor = rank <= 3 ? Colors.amber : Colors.grey;
    IconData rankIcon = rank == 1 ? Icons.looks_one :
                       rank == 2 ? Icons.looks_two :
                       rank == 3 ? Icons.looks_3 : Icons.inventory;

    // Calculate performance metrics
    final avgQuantityPerDelivery = item.deliveryCount > 0
        ? item.totalQuantityDelivered / item.deliveryCount
        : 0.0;
    final avgRevenuePerDelivery = item.deliveryCount > 0
        ? item.totalRevenue / item.deliveryCount
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: rankColor,
          child: Icon(rankIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          item.product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Revenue: \$${item.totalRevenue.toStringAsFixed(2)} • ${item.totalQuantityDelivered.toStringAsFixed(1)} ${item.product.unit}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Total Quantity',
                        '${item.totalQuantityDelivered.toStringAsFixed(1)} ${item.product.unit}',
                        Icons.straighten,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Total Revenue',
                        '\$${item.totalRevenue.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Deliveries',
                        item.deliveryCount.toString(),
                        Icons.local_shipping,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Avg per Delivery',
                        avgQuantityPerDelivery.toStringAsFixed(1),
                        Icons.analytics,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Unit Price',
                              '\$${item.product.price.toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Unit Type',
                              item.product.unit,
                              Icons.straighten,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Avg Revenue/Delivery',
                              '\$${avgRevenuePerDelivery.toStringAsFixed(2)}',
                              Icons.trending_up,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Performance',
                              _getPerformanceRating(item),
                              Icons.star,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

  Widget _buildProductDetail(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.all(2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceRating(ProductPerformanceItem item) {
    if (item.totalRevenue > 1000) return 'Excellent';
    if (item.totalRevenue > 500) return 'Good';
    if (item.totalRevenue > 100) return 'Average';
    if (item.totalRevenue > 0) return 'Low';
    return 'No Sales';
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
        _sortAscending = false; // Default to descending for performance metrics
      }
      _applySorting();
    });
  }
}