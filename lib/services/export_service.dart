import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../models/product_variant.dart';

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  // ── CSV Export ─────────────────────────────────────────────────────────────

  Future<void> exportToCsv(
    List<Product> products, {
    Map<String, String> categoryNames = const {},
    Map<String, String> warehouseNames = const {},
    String currency = 'USD',
  }) async {
    final rows = <List<dynamic>>[
      [
        'ID', 'Name', 'SKU', 'Description', 'Category', 'Warehouse',
        'Price ($currency)', 'Stock', 'Low Stock Threshold', 'Supplier',
        'Total Value ($currency)', 'Status',
      ],
    ];

    for (final p in products) {
      final isLow = p.stock <= p.lowStockThreshold;
      rows.add([
        p.id,
        p.name,
        p.sku,
        p.description,
        categoryNames[p.categoryId] ?? p.categoryId,
        warehouseNames[p.warehouseId] ?? p.warehouseId,
        p.price.toStringAsFixed(2),
        p.stock,
        p.lowStockThreshold,
        p.supplier,
        (p.price * p.stock).toStringAsFixed(2),
        p.stock == 0 ? 'Out of Stock' : (isLow ? 'Low Stock' : 'In Stock'),
      ]);

      final variants = ProductVariant.decodeList(p.variantsJson);
      for (final v in variants) {
        rows.add([
          '  └ variant',
          '  ${v.name}',
          v.sku ?? '',
          '',
          '',
          '',
          (v.price ?? p.price).toStringAsFixed(2),
          v.stock,
          '',
          '',
          ((v.price ?? p.price) * v.stock).toStringAsFixed(2),
          '',
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);
    await _shareText(csv, 'inventory_export.csv', 'text/csv');
  }

  // ── PDF Export ─────────────────────────────────────────────────────────────

  Future<void> exportToPdf(
    List<Product> products, {
    Map<String, String> categoryNames = const {},
    Map<String, String> warehouseNames = const {},
    String currency = 'USD',
  }) async {
    final pdf = pw.Document();

    final totalValue =
        products.fold<double>(0, (s, p) => s + p.price * p.stock);
    final lowCount = products.where((p) => p.stock <= p.lowStockThreshold).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Inventory Report',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  _formatDate(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              _summaryChip('Total Products', products.length.toString()),
              pw.SizedBox(width: 12),
              _summaryChip(
                  'Total Value', '$currency ${totalValue.toStringAsFixed(2)}'),
              pw.SizedBox(width: 12),
              _summaryChip('Low Stock', lowCount.toString()),
            ]),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (_) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                children: [
                  _headerCell('Product Name'),
                  _headerCell('SKU'),
                  _headerCell('Category'),
                  _headerCell('Stock'),
                  _headerCell('Price'),
                  _headerCell('Value'),
                ],
              ),
              ...products.map((p) {
                final isLow = p.stock <= p.lowStockThreshold;
                final rowColor =
                    p.stock == 0 ? PdfColors.red50 : (isLow ? PdfColors.orange50 : PdfColors.white);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _cell(p.name),
                    _cell(p.sku, fontSize: 9),
                    _cell(categoryNames[p.categoryId] ?? '—', fontSize: 9),
                    _cell(p.stock.toString(),
                        color: p.stock == 0
                            ? PdfColors.red
                            : (isLow ? PdfColors.orange900 : PdfColors.black)),
                    _cell('$currency ${p.price.toStringAsFixed(2)}', fontSize: 9),
                    _cell(
                        '$currency ${(p.price * p.stock).toStringAsFixed(2)}',
                        fontSize: 9),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await _shareBytes(bytes, 'inventory_report.pdf', 'application/pdf');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  pw.Widget _summaryChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _cell(String text,
          {double fontSize = 9, PdfColor color = PdfColors.black}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: fontSize, color: color)),
      );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _shareText(String content, String filename, String mime) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path, mimeType: mime)],
        subject: filename);
  }

  Future<void> _shareBytes(
      List<int> bytes, String filename, String mime) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mime)],
        subject: filename);
  }
}
