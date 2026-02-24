import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/inventory_provider.dart';
import 'product_details_screen.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final lowStock = inventory.lowStockProducts
      ..sort((a, b) => a.stock.compareTo(b.stock));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: lowStock.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  const Text('All stock levels are healthy!',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lowStock.length,
              itemBuilder: (context, index) {
                final product = lowStock[index];
                final percent = product.lowStockThreshold > 0
                    ? (product.stock / product.lowStockThreshold).clamp(0.0, 1.0)
                    : 0.0;
                final isOutOfStock = product.stock == 0;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(productId: product.id),
                      ),
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOutOfStock
                            ? Icons.remove_shopping_cart_outlined
                            : Icons.warning_amber_rounded,
                        color:
                            isOutOfStock ? Colors.red : Colors.orange[700],
                      ),
                    ),
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.grey[200],
                                  color: isOutOfStock
                                      ? Colors.red
                                      : Colors.orange,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${product.stock}/${product.lowStockThreshold}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock
                                      ? Colors.red
                                      : Colors.orange[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOutOfStock
                              ? 'Out of stock'
                              : '${product.lowStockThreshold - product.stock} units below threshold',
                          style: TextStyle(
                              fontSize: 12,
                              color: isOutOfStock ? Colors.red : Colors.orange[700]),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }
}
