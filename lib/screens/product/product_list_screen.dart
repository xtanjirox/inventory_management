import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final currency = Provider.of<AuthProvider>(context, listen: false).currentUser?.currency ?? 'USD';
    final primary = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    final categories = [
      {'id': 'All', 'name': 'All'},
      ...inventory.categories.map((c) => {'id': c.id, 'name': c.name}),
    ];

    final filteredProducts = inventory.products.where((p) {
      final q = _searchController.text.toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategoryId == 'All' || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    final lowStockCount = inventory.lowStockProducts.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            title: const Text('Products'),
            actions: [
              if (lowStockCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700]),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$lowStockCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // ── Search + filters ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or SKU…',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.grey[400]),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat['id'] == _selectedCategoryId;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategoryId = cat['id']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary
                                  : cs.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? primary
                                    : cs.outlineVariant,
                              ),
                            ),
                            child: Text(
                              cat['name']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Result count
                  Text(
                    '${filteredProducts.length} product${filteredProducts.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Empty state ───────────────────────────────────────────────────
          if (filteredProducts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No results for "${_searchController.text}"'
                          : 'No products yet',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first product',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Product list ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index];
                    final isLowStock = inventory.isProductLowStock(product);
                    final category = inventory.getCategoryById(product.categoryId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailsScreen(productId: product.id),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Product image / icon
                              Container(
                                width: 76,
                                height: 76,
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(12),
                                  image: product.imageUrl != null
                                      ? DecorationImage(
                                          image:
                                              NetworkImage(product.imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: product.imageUrl == null
                                    ? Icon(Icons.inventory_2_outlined,
                                        color: primary.withValues(alpha: 0.5),
                                        size: 28)
                                    : null,
                              ),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: cs.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      if (category != null)
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurface.withValues(alpha: 0.45)),
                                        ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _StockBadge(
                                            stock: product.stock,
                                            isLow: isLowStock,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Price
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$currency ${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(Icons.chevron_right_rounded,
                                        color: cs.onSurface.withValues(alpha: 0.2), size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filteredProducts.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  final bool isLow;
  const _StockBadge({required this.stock, required this.isLow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLow ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 11,
            color: isLow ? Colors.red[600] : Colors.green[600],
          ),
          const SizedBox(width: 4),
          Text(
            '$stock in stock',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLow ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
