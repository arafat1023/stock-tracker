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
  String _sortBy = 'revenue'; // revenue, deliveries, avg_order
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
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
        case 'avg_order':
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
            tooltip: 'Select Date Range',
          ),
          PopupMenuButton<String>(
            onSelected: _handleSortAction,
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Shops',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'revenue',
                child: Text('Sort by Total Sales', style: TextStyle(fontWeight: _sortBy == 'revenue' ? FontWeight.bold : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'deliveries',
                child: Text('Sort by Most Deliveries', style: TextStyle(fontWeight: _sortBy == 'deliveries' ? FontWeight.bold : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'avg_order',
                child: Text('Sort by Average Sale', style: TextStyle(fontWeight: _sortBy == 'avg_order' ? FontWeight.bold : FontWeight.normal)),
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
                              'No sales data found for this period.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _shopItems.length,
                            itemBuilder: (context, index) {
                              final item = _shopItems[index];
                              return _buildShopPerformanceCard(item, index + 1);
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
    final totalRevenue = _shopItems.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final totalDeliveries = _shopItems.fold(0, (sum, item) => sum + item.totalDeliveries);

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
              _buildSummaryItem('Total Deliveries', totalDeliveries.toString(), Icons.local_shipping, Colors.orange),
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

  Widget _buildShopPerformanceCard(ShopPerformanceItem item, int rank) {
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
                    item.shop.name,
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
                _buildStatItem('Deliveries', item.totalDeliveries.toString()),
                _buildStatItem('Avg. Sale', '৳${item.averageOrderValue.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 12),
            if (item.shop.address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(item.shop.address, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
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
      _loadShopReport();
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
