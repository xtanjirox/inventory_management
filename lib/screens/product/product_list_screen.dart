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
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final categories = [{'id': 'All', 'name': 'All'}, ...inventory.categories.map((c) => {'id': c.id, 'name': c.name})];

    final filteredProducts = inventory.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategoryId == 'All' || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category['id'] == _selectedCategoryId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = category['id']!;
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isLowStock = product.stock <= product.lowStockThreshold;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              image: product.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(product.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: product.imageUrl == null ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('SKU: ${product.sku}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.red[50] : Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${product.stock} in stock',
                                      style: TextStyle(
                                        color: isLowStock ? Colors.red : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${Provider.of<AuthProvider>(context, listen: false).currentUser?.currency ?? 'USD'} ${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Tap to view details',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  productId: product.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
