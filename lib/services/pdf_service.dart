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

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  Future<void> generateDeliveryNote({
    required Delivery delivery,
    required Shop shop,
    required List<DeliveryItem> items,
    required List<Product> products,
    bool share = false,
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
    } else {
      await _printPDF(pdf);
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
                  _buildTableCell('\$${item.unitPrice.toStringAsFixed(2)}'),
                  _buildTableCell('\$${item.totalPrice.toStringAsFixed(2)}'),
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
                '\$${delivery.totalAmount.toStringAsFixed(2)}',
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

  Future<void> generateStockReport({
    required List<Product> products,
    required Map<int, double> stockBalances,
    bool share = false,
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
    } else {
      await _printPDF(pdf);
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
              _buildTableCell('\$${product.price.toStringAsFixed(2)}'),
              _buildTableCell(stock.toStringAsFixed(1)),
              _buildTableCell('\$${stockValue.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }
}