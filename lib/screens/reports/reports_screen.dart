import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../../services/pdf_service.dart';
import '../../services/csv_service.dart';
import 'stock_report_screen.dart';
import 'shop_report_screen.dart';
import 'product_report_screen.dart';
import 'transaction_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final CSVService _csvService = CSVService();
  final PDFService _pdfService = PDFService();
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
            tooltip: 'Export Data',
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
                    _buildReportCategories(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardOverview() {
    if (_dashboardMetrics == null) {
      return const Center(
        child: Text('No data available to generate reports.'),
      );
    }

    final metrics = _dashboardMetrics!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'At a Glance',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here is a quick summary of your business.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _buildMetricCard(
              'Total Sales',
              '৳${metrics.totalRevenue.toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.teal,
            ),
            _buildMetricCard(
              'Inventory Value',
              '৳${metrics.totalStockValue.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.purple,
            ),
            _buildMetricCard(
              'Pending Deliveries',
              metrics.pendingDeliveries.toString(),
              Icons.pending,
              Colors.orange,
            ),
            _buildMetricCard(
              'Total Deliveries',
              metrics.totalDeliveries.toString(),
              Icons.local_shipping,
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Reports',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dive deeper into your sales, inventory, and customers.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        _buildReportCategoryCard(
          'Stock Report',
          'Check inventory levels and see what\'s out of stock.',
          Icons.inventory_2,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCategoryCard(
          'Best-Selling Products',
          'See which products are your top performers.',
          Icons.star,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCategoryCard(
          'Product Transactions',
          'Track all product movements - incoming, outgoing, and deliveries.',
          Icons.swap_horiz,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCategoryCard(
          'Shop Performance',
          'Analyze sales and deliveries for each shop.',
          Icons.store,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShopReportScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCategoryCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
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
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
              'Export Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export Stock Report as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportStockReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export All Sales Data as CSV'),
              subtitle: const Text('Export detailed sales and delivery data'),
              onTap: () {
                Navigator.pop(context);
                _exportCSVData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Export Summary Report as PDF'),
              subtitle: const Text('Business overview with key metrics'),
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

  void _exportCSVData() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV Data'),
        content: const Text('Choose what to export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'sales'),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Sales Data'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'products'),
            icon: const Icon(Icons.inventory),
            label: const Text('Products'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'shops'),
            icon: const Icon(Icons.store),
            label: const Text('Shops'),
          ),
        ],
      ),
    );

    if (action == null || action == 'cancel') return;

    try {
      setState(() => _isLoading = true);

      switch (action) {
        case 'sales':
          await _csvService.exportAllSalesData();
          break;
        case 'products':
          await _csvService.exportProductSummary();
          break;
        case 'shops':
          await _csvService.exportShopSummary();
          break;
        default:
          return;
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully and ready to share!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  void _exportSummaryReport() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Summary Report'),
        content: const Text('How would you like to handle the PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'download'),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'share'),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );

    if (action == null || action == 'cancel') return;

    try {
      setState(() => _isLoading = true);

      final filePath = await _pdfService.generateBusinessSummaryReport(
        share: action == 'share',
        download: action == 'download',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (action == 'download' && filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF downloaded to: $filePath'),
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (action == 'share') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF generated and ready to share!')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }
}
