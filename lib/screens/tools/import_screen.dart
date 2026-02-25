import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/inventory_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<_ParsedRow> _preview = [];
  String? _errorMsg;
  bool _importing = false;
  bool _imported = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() { _errorMsg = null; _preview = []; _imported = false; });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final String content;
    if (file.bytes != null) {
      content = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      setState(() => _errorMsg = 'Could not read file.');
      return;
    }

    _parseCSV(content);
  }

  void _parseCSV(String content) {
    try {
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) {
        setState(() => _errorMsg = 'File is empty.');
        return;
      }

      final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final nameIdx = _col(header, ['name', 'product name', 'product']);
      final skuIdx = _col(header, ['sku', 'barcode', 'code']);
      final priceIdx = _col(header, ['price', 'unit price', 'cost']);
      final stockIdx = _col(header, ['stock', 'quantity', 'qty', 'units']);
      final descIdx = _col(header, ['description', 'desc', 'details']);
      final supplierIdx = _col(header, ['supplier', 'vendor', 'brand']);
      final thresholdIdx = _col(header, ['low stock threshold', 'threshold', 'min stock', 'low stock']);

      if (nameIdx == -1 || skuIdx == -1) {
        setState(() => _errorMsg = 'Missing required columns: "name" and "sku".');
        return;
      }

      final parsed = <_ParsedRow>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

        String g(int idx) => idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';

        final name = g(nameIdx);
        final sku = g(skuIdx);
        if (name.isEmpty || sku.isEmpty) continue;

        parsed.add(_ParsedRow(
          name: name,
          sku: sku,
          price: double.tryParse(g(priceIdx).replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
          stock: int.tryParse(g(stockIdx)) ?? 0,
          description: g(descIdx),
          supplier: g(supplierIdx),
          lowStockThreshold: int.tryParse(g(thresholdIdx)) ?? 10,
        ));
      }

      if (parsed.isEmpty) {
        setState(() => _errorMsg = 'No valid rows found in file.');
        return;
      }

      setState(() => _preview = parsed);
      _tabs.animateTo(1);
    } catch (e) {
      setState(() => _errorMsg = 'Parse error: $e');
    }
  }

  int _col(List<String> header, List<String> names) {
    for (final n in names) {
      final i = header.indexOf(n);
      if (i >= 0) return i;
    }
    return -1;
  }

  Future<void> _importProducts() async {
    if (_preview.isEmpty) return;
    setState(() => _importing = true);

    final inventory = context.read<InventoryProvider>();

    final categories = inventory.categories;
    final warehouses = inventory.warehouses;

    final defaultCategoryId =
        categories.isNotEmpty ? categories.first.id : '';
    final defaultWarehouseId =
        warehouses.isNotEmpty ? warehouses.first.id : '';

    if (defaultCategoryId.isEmpty || defaultWarehouseId.isEmpty) {
      setState(() {
        _importing = false;
        _errorMsg = 'No categories or warehouses found. Please create them first.';
      });
      return;
    }

    int successCount = 0;
    for (final row in _preview) {
      try {
        final existing = inventory.getProductById(row.sku);
        if (existing != null) {
          await inventory.updateProduct(existing.copyWith(
            name: row.name,
            description: row.description,
            price: row.price,
            stock: row.stock,
            lowStockThreshold: row.lowStockThreshold,
            supplier: row.supplier,
          ));
        } else {
          await inventory.addProduct(Product(
            name: row.name,
            sku: row.sku,
            description: row.description,
            categoryId: defaultCategoryId,
            warehouseId: defaultWarehouseId,
            price: row.price,
            stock: row.stock,
            lowStockThreshold: row.lowStockThreshold,
            supplier: row.supplier,
          ));
        }
        successCount++;
      } catch (_) {}
    }

    setState(() { _importing = false; _imported = true; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imported $successCount / ${_preview.length} products'),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Format Guide'),
            Tab(text: 'Preview & Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Format Guide ─────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(
                  icon: Icons.info_outline_rounded,
                  color: cs.primary,
                  title: 'Supported Format',
                  body:
                      'Upload a CSV (.csv) file with the first row as column headers. '
                      'Only "name" and "sku" are required — all other columns are optional.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Required Columns',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary)),
                      const SizedBox(height: 10),
                      _colRow('name', 'Product name', required: true),
                      _colRow('sku', 'Unique product code / barcode',
                          required: true),
                      const Divider(height: 20),
                      Text('Optional Columns',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 10),
                      _colRow('description', 'Product description'),
                      _colRow('price', 'Unit price (number)'),
                      _colRow('stock', 'Current stock quantity (integer)'),
                      _colRow('low stock threshold',
                          'Min stock before alert (integer, default: 10)'),
                      _colRow('supplier', 'Supplier / vendor name'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Example CSV',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          'name,sku,price,stock,low stock threshold,description,supplier\n'
                          'Wireless Headphones,WH-001,129.99,50,10,Premium ANC headphones,AudioTech\n'
                          'Cotton T-Shirt,TS-001,19.99,200,20,100% cotton,Apparel Co\n'
                          'Smart Watch,SW-001,199.99,30,5,GPS + heart rate,TechGear',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.sync_rounded,
                  color: Colors.orange,
                  title: 'Update Existing Products',
                  body:
                      'If a product with the same SKU already exists, it will be '
                      'updated with the new data from the CSV. Otherwise, a new '
                      'product will be created.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Select CSV File'),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab 2: Preview & Import ─────────────────────────────────────
          Column(
            children: [
              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              if (_preview.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_chart_outlined,
                            size: 48,
                            color: cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text('No file loaded yet',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Select CSV File'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_preview.length} products found',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.change_circle_outlined, size: 16),
                        label: const Text('Change File'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _preview.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final row = _preview[i];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 2),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              cs.primary.withValues(alpha: 0.1),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(row.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                            'SKU: ${row.sku}  ·  Stock: ${row.stock}  ·  Price: ${row.price.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.5))),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _importing || _imported ? null : _importProducts,
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(_imported
                              ? Icons.check_circle_rounded
                              : Icons.download_rounded),
                      label: Text(_importing
                          ? 'Importing…'
                          : _imported
                              ? 'Import Complete'
                              : 'Import ${_preview.length} Products'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _colRow(String col, String desc, {bool required = false}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(col,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: required ? cs.primary : cs.onSurface)),
          ),
          if (required)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('required',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: Text(desc,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    final surface = Theme.of(context).colorScheme.surface;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedRow {
  final String name;
  final String sku;
  final double price;
  final int stock;
  final String description;
  final String supplier;
  final int lowStockThreshold;

  const _ParsedRow({
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.description,
    required this.supplier,
    required this.lowStockThreshold,
  });
}
