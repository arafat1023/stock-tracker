import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';

class ShopReportScreen extends StatefulWidget {
  const ShopReportScreen({super.key});

  @override
  State<ShopReportScreen> createState() => _ShopReportScreenState();
}

class _ShopReportScreenState extends State<ShopReportScreen> {
  final ReportService _reportService = ReportService();
  List<ShopPerformanceItem> _shopItems = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'revenue'; // revenue, deliveries, orders
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadShopReport();
  }

  Future<void> _loadShopReport() async {
    setState(() => _isLoading = true);
    try {
      final items = await _reportService.getShopPerformanceReport(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _shopItems = items;
        _isLoading = false;
        _applySorting();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shop report: $e')),
        );
      }
    }
  }

  void _applySorting() {
    _shopItems.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'revenue':
          comparison = a.totalRevenue.compareTo(b.totalRevenue);
          break;
        case 'deliveries':
          comparison = a.totalDeliveries.compareTo(b.totalDeliveries);
          break;
        case 'orders':
          comparison = a.averageOrderValue.compareTo(b.averageOrderValue);
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
        title: const Text('Shop Performance'),
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
                value: 'deliveries',
                child: Row(
                  children: [
                    Icon(_sortBy == 'deliveries' ? Icons.check : Icons.local_shipping),
                    const SizedBox(width: 8),
                    const Text('Sort by Deliveries'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(_sortBy == 'orders' ? Icons.check : Icons.analytics),
                    const SizedBox(width: 8),
                    const Text('Sort by Avg Order'),
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
              onRefresh: _loadShopReport,
              child: Column(
                children: [
                  _buildDateRangeCard(),
                  _buildSummaryCard(),
                  Expanded(
                    child: _shopItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No shop data found for selected period',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _shopItems.length,
                            itemBuilder: (context, index) {
                              final item = _shopItems[index];
                              return _buildShopPerformanceTile(item, index + 1);
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
    final totalShops = _shopItems.length;
    final totalRevenue = _shopItems.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final totalDeliveries = _shopItems.fold(0, (sum, item) => sum + item.totalDeliveries);
    final avgRevenue = totalShops > 0 ? totalRevenue / totalShops : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Active Shops',
                    totalShops.toString(),
                    Icons.store,
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
                    'Total Deliveries',
                    totalDeliveries.toString(),
                    Icons.local_shipping,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Avg per Shop',
                    '\$${avgRevenue.toStringAsFixed(2)}',
                    Icons.analytics,
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

  Widget _buildShopPerformanceTile(ShopPerformanceItem item, int rank) {
    Color rankColor = rank <= 3 ? Colors.amber : Colors.grey;
    IconData rankIcon = rank == 1 ? Icons.looks_one :
                       rank == 2 ? Icons.looks_two :
                       rank == 3 ? Icons.looks_3 : Icons.store;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: rankColor,
          child: Icon(rankIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          item.shop.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Revenue: \$${item.totalRevenue.toStringAsFixed(2)} • ${item.totalDeliveries} deliveries',
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
                        'Total Deliveries',
                        item.totalDeliveries.toString(),
                        Icons.local_shipping,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Completed',
                        item.completedDeliveries.toString(),
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Total Revenue',
                        '\$${item.totalRevenue.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Avg Order Value',
                        '\$${item.averageOrderValue.toStringAsFixed(2)}',
                        Icons.analytics,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Address: ${item.shop.address}'),
                      if (item.shop.contact.isNotEmpty)
                        Text('Contact: ${item.shop.contact}'),
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
      _loadShopReport();
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