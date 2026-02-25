import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../models/activity.dart';
import '../../models/product_variant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/app_dialogs.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  void _showAdjustStockDialog(BuildContext context, InventoryProvider inventory) {
    final product = inventory.getProductById(widget.productId);
    if (product == null) return;
    final variants = ProductVariant.decodeList(product.variantsJson);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockOperationSheet(
        product: product,
        variants: variants,
        onConfirm: (type, delta, note, variantId) async {
          if (variantId != null) {
            final v = variants.firstWhere((v) => v.id == variantId);
            final newVStock = (v.stock + delta).clamp(0, 999999).toInt();
            await inventory.adjustVariantStock(product.id, variantId, newVStock,
                type: type, note: note);
            if (context.mounted) {
              AppDialogs.snack(context, '${v.name} stock → $newVStock units', success: true);
            }
          } else {
            final newStock = (product.stock + delta).clamp(0, 999999).toInt();
            await inventory.adjustStock(product.id, newStock, type: type, note: note);
            if (context.mounted) {
              AppDialogs.snack(context, 'Stock updated → $newStock units', success: true);
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, InventoryProvider inventory) {
    AppDialogs.confirmDelete(
      context: context,
      title: 'Delete Product',
      message: 'This product will be permanently removed from your inventory. This action cannot be undone.',
      onConfirm: () async {
        await inventory.deleteProduct(widget.productId);
        if (context.mounted) {
          Navigator.pop(context);
          AppDialogs.snack(context, 'Product deleted', success: true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;
    final product = inventory.getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final category = inventory.getCategoryById(product.categoryId);
    final warehouse = inventory.getWarehouseById(product.warehouseId);
    final variants = ProductVariant.decodeList(product.variantsJson);
    final hasVariants = variants.isNotEmpty;
    final isLowStock = inventory.isProductLowStock(product);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(productToEdit: product),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, inventory),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outlineVariant),
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          category?.name ?? 'Unknown Category',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${user?.currency ?? 'USD'} ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (product.description.isNotEmpty && product.description != '') ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    'SKU / Barcode',
                    product.sku,
                    Icons.qr_code_2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    'In Stock',
                    hasVariants
                        ? '${inventory.effectiveStock(product)} units total'
                        : '${product.stock} units',
                    Icons.inventory_2_outlined,
                    valueColor: isLowStock ? Colors.red : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAdjustStockDialog(context, inventory),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Restock / Adjust Stock'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    'Supplier',
                    product.supplier.isEmpty ? '—' : product.supplier,
                    Icons.local_shipping_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    'Warehouse',
                    warehouse?.name ?? 'Unknown',
                    Icons.place_outlined,
                  ),
                ),
              ],
            ),

            // ── Variants section ──────────────────────────────────────────
            if (hasVariants) ..._buildVariantsSection(context, variants, product.lowStockThreshold, cs),

            const SizedBox(height: 48),
            if (product.sku.isNotEmpty && product.sku != '') ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: BarcodeWidget(
                    barcode: Barcode.code128(), // Barcode type
                    data: product.sku,
                    width: 200,
                    height: 80,
                    drawText: true,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Export barcode logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barcode exported successfully')),
                  );
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Export Barcode'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVariantsSection(
    BuildContext context,
    List<ProductVariant> variants,
    int threshold,
    dynamic colorScheme,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return [
      const SizedBox(height: 24),
      const Text('Variants',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < variants.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.07)),
              _VariantRow(
                variant: variants[i],
                threshold: threshold,
                primary: primary,
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

// ── Stock Operation Bottom Sheet ───────────────────────────────────────────────

typedef _OpCallback = Future<void> Function(
    ActivityType type, int delta, String? note, String? variantId);

class _StockOperationSheet extends StatefulWidget {
  final dynamic product;
  final List<ProductVariant> variants;
  final _OpCallback onConfirm;
  const _StockOperationSheet(
      {required this.product, required this.variants, required this.onConfirm});

  @override
  State<_StockOperationSheet> createState() => _StockOperationSheetState();
}

class _StockOperationSheetState extends State<_StockOperationSheet> {
  static const _ops = [
    _Op(ActivityType.restock, 'Restock', Icons.add_circle_outline_rounded,
        Color(0xFF16A34A), true),
    _Op(ActivityType.sale, 'Sale', Icons.shopping_cart_outlined,
        Color(0xFF2563EB), false),
    _Op(ActivityType.returnToStock, 'Return', Icons.undo_rounded,
        Color(0xFFD97706), true),
    _Op(ActivityType.damagedArticle, 'Damage', Icons.warning_amber_rounded,
        Color(0xFFDC2626), false),
    _Op(ActivityType.stockAdjustment, 'Adjustment', Icons.tune_rounded,
        Color(0xFF6B7280), true),
  ];

  int _selectedOp = 0;
  int _selectedVariantIdx = 0;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final op = _ops[_selectedOp];
    final hasVariants = widget.variants.isNotEmpty;
    final currentStock = hasVariants
        ? widget.variants[_selectedVariantIdx].stock
        : widget.product.stock as int;
    final selectedVariantId =
        hasVariants ? widget.variants[_selectedVariantIdx].id : null;
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    final delta = op.isAddition ? amount : -amount;
    final preview = (currentStock + delta).clamp(0, 999999);

    final surface = Theme.of(context).colorScheme.surface;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 16,
          left: 24,
          right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Adjust Stock',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            hasVariants
                ? 'Variant: ${widget.variants[_selectedVariantIdx].name} · $currentStock units'
                : 'Current: $currentStock units',
            style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),

          // Variant picker
          if (hasVariants) ...[  
            DropdownButtonFormField<int>(
              value: _selectedVariantIdx,
              decoration: const InputDecoration(
                labelText: 'Select variant',
                isDense: true,
              ),
              items: [
                for (int i = 0; i < widget.variants.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      '${widget.variants[i].name}  (${widget.variants[i].stock} in stock)',
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() { _selectedVariantIdx = v; _amountCtrl.clear(); });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Operation type chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _ops.length,
              itemBuilder: (_, i) {
                final o = _ops[i];
                final sel = i == _selectedOp;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOp = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? o.color.withValues(alpha: 0.12)
                          : cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? o.color : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(o.icon,
                            size: 16,
                            color: sel
                                ? o.color
                                : cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(o.label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: sel
                                    ? o.color
                                    : cs.onSurface.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Amount field
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: op.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                    op.isAddition
                        ? Icons.add_rounded
                        : Icons.remove_rounded,
                    color: op.color,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: op.label == 'Adjustment'
                        ? 'New total quantity'
                        : 'Quantity',
                    hintText: '0',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Note field
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Supplier delivery #1234',
            ),
          ),
          const SizedBox(height: 16),

          // Preview
          if (_amountCtrl.text.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: op.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: op.color),
                  const SizedBox(width: 8),
                  Text(
                    'New stock: $currentStock '
                    '${op.isAddition ? '+' : '-'} $amount = $preview units',
                    style: TextStyle(
                        fontSize: 13,
                        color: op.color,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final raw = int.tryParse(_amountCtrl.text);
                      if (raw == null || raw <= 0) return;
                      setState(() => _saving = true);
                      final d = op.label == 'Adjustment'
                          ? raw - currentStock
                          : (op.isAddition ? raw : -raw);
                      await widget.onConfirm(
                          op.type, d, _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(), selectedVariantId);
                      if (mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Apply ${op.label}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Op {
  final ActivityType type;
  final String label;
  final IconData icon;
  final Color color;
  final bool isAddition;
  const _Op(this.type, this.label, this.icon, this.color, this.isAddition);
}

// ── Variant row ────────────────────────────────────────────────────────────────

class _VariantRow extends StatelessWidget {
  final ProductVariant variant;
  final int threshold;
  final Color primary;
  const _VariantRow(
      {required this.variant, required this.threshold, required this.primary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLow = variant.stock <= threshold;
    final isOut = variant.stock == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.label_outline_rounded,
                color: primary.withValues(alpha: 0.6), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface)),
                if (variant.sku != null && variant.sku!.isNotEmpty)
                  Text('SKU: ${variant.sku}',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOut
                      ? Colors.red.withValues(alpha: 0.1)
                      : isLow
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOut ? 'Out of stock' : '${variant.stock} units',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOut
                        ? Colors.red[700]
                        : isLow
                            ? Colors.orange[700]
                            : Colors.green[700],
                  ),
                ),
              ),
              if (variant.price != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${variant.price!.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
