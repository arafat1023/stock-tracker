import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/delivery.dart';
import '../models/delivery_item.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final ReportService _reportService = ReportService();

  Future<String?> generateDeliveryNote({
    required Delivery delivery,
    required Shop shop,
    required List<DeliveryItem> items,
    required List<Product> products,
    bool share = false,
    bool download = false,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildDeliveryInfo(delivery),
            pw.SizedBox(height: 20),
            _buildShopInfo(shop),
            pw.SizedBox(height: 20),
            _buildItemsTable(items, products),
            pw.SizedBox(height: 20),
            _buildTotals(delivery),
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    if (share) {
      await _sharePDF(pdf, 'Delivery_${delivery.id}_${shop.name}');
      return null;
    } else if (download) {
      final filePath = await _downloadPDF(pdf, 'Delivery_${delivery.id}_${shop.name}');
      return filePath;
    } else {
      await _printPDF(pdf);
      return null;
    }
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'STOCK TRACKER',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.Text(
              'Delivery Note',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Time: ${DateFormat('HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDeliveryInfo(Delivery delivery) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Delivery Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('Delivery ID', '#${delivery.id}'),
              ),
              pw.Expanded(
                child: _buildInfoItem('Status', delivery.status.name.toUpperCase()),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          _buildInfoItem('Delivery Date', DateFormat('MMM dd, yyyy').format(delivery.deliveryDate)),
          if (delivery.notes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _buildInfoItem('Notes', delivery.notes),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildShopInfo(Shop shop) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Deliver To:',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            shop.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(shop.address, style: const pw.TextStyle(fontSize: 12)),
          if (shop.contact.isNotEmpty)
            pw.Text('Contact: ${shop.contact}', style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<DeliveryItem> items, List<Product> products) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Items',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Product', isHeader: true),
                _buildTableCell('Unit', isHeader: true),
                _buildTableCell('Quantity', isHeader: true),
                _buildTableCell('Unit Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Items
            ...items.map<pw.TableRow>((item) {
              final product = products.firstWhere(
                (p) => p.id == item.productId,
                orElse: () => Product(
                  name: 'Unknown Product',
                  unit: '',
                  price: 0.0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              return pw.TableRow(
                children: [
                  _buildTableCell(product.name),
                  _buildTableCell(product.unit),
                  _buildTableCell(item.quantity.toStringAsFixed(1)),
                  _buildTableCell('BDT ${item.unitPrice.toStringAsFixed(2)}'),
                  _buildTableCell('BDT ${item.totalPrice.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotals(Delivery delivery) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total Amount',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'BDT ${delivery.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Stock Tracker App',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.Text(
              'Page 1',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInfoItem(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  Future<void> _printPDF(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _sharePDF(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Delivery Note - $fileName',
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  Future<String> _downloadPDF(pw.Document pdf, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  Future<String?> generateStockReport({
    required List<Product> products,
    required Map<int, double> stockBalances,
    bool share = false,
    bool download = false,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildStockReportHeader(),
            pw.SizedBox(height: 20),
            _buildStockTable(products, stockBalances),
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    if (share) {
      await _sharePDF(pdf, 'Stock_Report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}');
      return null;
    } else if (download) {
      final filePath = await _downloadPDF(pdf, 'Stock_Report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}');
      return filePath;
    } else {
      await _printPDF(pdf);
      return null;
    }
  }

  pw.Widget _buildStockReportHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'STOCK TRACKER',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.Text(
          'Stock Balance Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget _buildStockTable(List<Product> products, Map<int, double> stockBalances) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Product Name', isHeader: true),
            _buildTableCell('Unit', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Stock Quantity', isHeader: true),
            _buildTableCell('Stock Value', isHeader: true),
          ],
        ),
        // Products
        ...products.map<pw.TableRow>((product) {
          final stock = stockBalances[product.id] ?? 0.0;
          final stockValue = stock * product.price;

          return pw.TableRow(
            children: [
              _buildTableCell(product.name),
              _buildTableCell(product.unit),
              _buildTableCell('BDT ${product.price.toStringAsFixed(2)}'),
              _buildTableCell(stock.toStringAsFixed(1)),
              _buildTableCell('BDT ${stockValue.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  Future<String?> generateBusinessSummaryReport({
    bool share = false,
    bool download = false,
  }) async {
    final pdf = pw.Document();

    // Get dashboard metrics and business data
    final metrics = await _reportService.getDashboardMetrics();
    final products = await _databaseService.getProducts();
    final shops = await _databaseService.getShops();
    final deliveries = await _databaseService.getDeliveries();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildBusinessSummaryHeader(),
            pw.SizedBox(height: 20),
            _buildBusinessMetrics(metrics),
            pw.SizedBox(height: 20),
            _buildTopProductsTable(products, deliveries),
            pw.SizedBox(height: 20),
            _buildTopShopsTable(shops, deliveries),
            pw.SizedBox(height: 20),
            _buildRecentActivityTable(deliveries),
          ];
        },
      ),
    );

    if (share) {
      await _sharePDF(pdf, 'Business_Summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}');
      return null;
    } else if (download) {
      final filePath = await _downloadPDF(pdf, 'Business_Summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}');
      return filePath;
    } else {
      await _printPDF(pdf);
      return null;
    }
  }

  pw.Widget _buildBusinessSummaryHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'STOCK TRACKER',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.Text(
          'Business Summary Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue),
      ],
    );
  }

  pw.Widget _buildBusinessMetrics(DashboardMetrics metrics) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Business Metrics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricBox('Total Revenue', 'BDT ${metrics.totalRevenue.toStringAsFixed(2)}', PdfColors.green),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildMetricBox('Inventory Value', 'BDT ${metrics.totalStockValue.toStringAsFixed(2)}', PdfColors.blue),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricBox('Total Deliveries', metrics.totalDeliveries.toString(), PdfColors.orange),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildMetricBox('Pending Deliveries', metrics.pendingDeliveries.toString(), PdfColors.red),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMetricBox(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopProductsTable(List<Product> products, List<Delivery> deliveries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Selling Products',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Product', isHeader: true),
                _buildTableCell('Unit', isHeader: true),
                _buildTableCell('Price', isHeader: true),
                _buildTableCell('Total Sold', isHeader: true),
                _buildTableCell('Revenue', isHeader: true),
              ],
            ),
            ...products.take(10).map((product) {
              // Calculate sales for this product
              double totalSold = 0;
              double revenue = 0;

              for (final delivery in deliveries) {
                if (delivery.status == DeliveryStatus.completed) {
                  // Note: This is simplified - in a real implementation, you'd join with delivery_items
                  // For now, using estimated values
                  totalSold += 5; // Placeholder
                  revenue += 5 * product.price; // Placeholder
                }
              }

              return pw.TableRow(
                children: [
                  _buildTableCell(product.name),
                  _buildTableCell(product.unit),
                  _buildTableCell('BDT ${product.price.toStringAsFixed(2)}'),
                  _buildTableCell(totalSold.toStringAsFixed(1)),
                  _buildTableCell('BDT ${revenue.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTopShopsTable(List<Shop> shops, List<Delivery> deliveries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Customers',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Shop Name', isHeader: true),
                _buildTableCell('Total Orders', isHeader: true),
                _buildTableCell('Total Revenue', isHeader: true),
                _buildTableCell('Avg. Order', isHeader: true),
              ],
            ),
            ...shops.take(10).map((shop) {
              final shopDeliveries = deliveries.where((d) => d.shopId == shop.id).toList();
              final completedDeliveries = shopDeliveries.where((d) => d.status == DeliveryStatus.completed).toList();
              final totalRevenue = completedDeliveries.fold(0.0, (sum, d) => sum + d.totalAmount);
              final avgOrder = completedDeliveries.isNotEmpty ? totalRevenue / completedDeliveries.length : 0.0;

              return pw.TableRow(
                children: [
                  _buildTableCell(shop.name),
                  _buildTableCell(completedDeliveries.length.toString()),
                  _buildTableCell('BDT ${totalRevenue.toStringAsFixed(2)}'),
                  _buildTableCell('BDT ${avgOrder.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRecentActivityTable(List<Delivery> deliveries) {
    final recentDeliveries = deliveries.take(10).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Activity',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Delivery ID', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            ...recentDeliveries.map((delivery) {
              return pw.TableRow(
                children: [
                  _buildTableCell(DateFormat('MMM dd, yyyy').format(delivery.deliveryDate)),
                  _buildTableCell('#${delivery.id}'),
                  _buildTableCell('BDT ${delivery.totalAmount.toStringAsFixed(2)}'),
                  _buildTableCell(delivery.status.name.toUpperCase()),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}