import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../../services/pdf_service.dart';
import 'stock_report_screen.dart';
import 'shop_report_screen.dart';
import 'product_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  DashboardMetrics? _dashboardMetrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
  }

  Future<void> _loadDashboardMetrics() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _reportService.getDashboardMetrics();
      setState(() {
        _dashboardMetrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.file_download),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardMetrics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardOverview(),
                    const SizedBox(height: 24),
                    _buildReportCategories(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardOverview() {
    if (_dashboardMetrics == null) {
      return const SizedBox.shrink();
    }

    final metrics = _dashboardMetrics!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Products',
              metrics.totalProducts.toString(),
              Icons.inventory,
              Colors.blue,
            ),
            _buildMetricCard(
              'Total Shops',
              metrics.totalShops.toString(),
              Icons.store,
              Colors.green,
            ),
            _buildMetricCard(
              'Total Deliveries',
              metrics.totalDeliveries.toString(),
              Icons.local_shipping,
              Colors.orange,
            ),
            _buildMetricCard(
              'Pending Deliveries',
              metrics.pendingDeliveries.toString(),
              Icons.pending,
              Colors.red,
            ),
            _buildMetricCard(
              'Stock Value',
              '\$${metrics.totalStockValue.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.purple,
            ),
            _buildMetricCard(
              'Total Revenue',
              '\$${metrics.totalRevenue.toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
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
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Reports',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildReportCategoryCard(
          'Stock Reports',
          'View inventory levels, stock movements, and alerts',
          Icons.inventory,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCategoryCard(
          'Shop Performance',
          'Analyze shop-wise deliveries, revenue, and trends',
          Icons.store,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShopReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCategoryCard(
          'Product Analytics',
          'Track product distribution and performance metrics',
          Icons.bar_chart,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCategoryCard(
          'Export Data',
          'Generate PDF reports and CSV exports',
          Icons.file_download,
          Colors.purple,
          _showExportOptions,
        ),
      ],
    );
  }

  Widget _buildReportCategoryCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export Stock Report (PDF)'),
              onTap: () {
                Navigator.pop(context);
                _exportStockReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export Data (CSV)'),
              onTap: () {
                Navigator.pop(context);
                _exportCSVData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Export Summary Report (PDF)'),
              onTap: () {
                Navigator.pop(context);
                _exportSummaryReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportStockReport() async {
    try {
      final stockItems = await _reportService.getStockBalanceReport();
      final products = stockItems.map((item) => item.product).toList();
      final stockBalances = Map.fromEntries(
        stockItems.map((item) => MapEntry(item.product.id!, item.currentStock)),
      );

      final pdfService = PDFService();
      await pdfService.generateStockReport(
        products: products,
        stockBalances: stockBalances,
        share: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting stock report: $e')),
        );
      }
    }
  }

  void _exportCSVData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export feature coming soon')),
    );
  }

  void _exportSummaryReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary report feature coming soon')),
    );
  }
}