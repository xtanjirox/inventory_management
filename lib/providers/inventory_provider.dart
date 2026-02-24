import 'package:flutter/material.dart';
import '../models/models.dart';

class InventoryProvider with ChangeNotifier {
  // Initial dummy data
  final List<Category> _categories = [
    Category(id: 'c1', name: 'Electronics'),
    Category(id: 'c2', name: 'Clothing'),
    Category(id: 'c3', name: 'Food'),
    Category(id: 'c4', name: 'Other'),
  ];

  final List<Warehouse> _warehouses = [
    Warehouse(id: 'w1', name: 'Main Warehouse', location: 'New York, NY'),
    Warehouse(id: 'w2', name: 'West Coast Hub', location: 'Los Angeles, CA'),
  ];

  final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Wireless Headphones',
      description: 'High-quality wireless headphones with noise cancellation.',
      categoryId: 'c1',
      warehouseId: 'w1',
      sku: 'WH-1001',
      price: 129.99,
      stock: 45,
      lowStockThreshold: 10,
      supplier: 'AudioTech Inc.',
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    ),
    Product(
      id: 'p2',
      name: 'Cotton T-Shirt',
      description: 'Comfortable 100% cotton t-shirt.',
      categoryId: 'c2',
      warehouseId: 'w2',
      sku: 'TS-2001',
      price: 19.99,
      stock: 120,
      lowStockThreshold: 20,
      supplier: 'Apparel Co.',
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    ),
    Product(
      id: 'p3',
      name: 'Smart Watch',
      description: 'Fitness tracking smartwatch with heart rate monitor.',
      categoryId: 'c1',
      warehouseId: 'w1',
      sku: 'SW-1002',
      price: 199.99,
      stock: 15, // Low stock
      lowStockThreshold: 20,
      supplier: 'TechGear',
      imageUrl: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    ),
  ];

  // Getters
  List<Category> get categories => [..._categories];
  List<Warehouse> get warehouses => [..._warehouses];
  List<Product> get products => [..._products];

  // Methods
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Warehouse? getWarehouseById(String id) {
    try {
      return _warehouses.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id || p.sku == id); // Search by ID or SKU (barcode)
    } catch (e) {
      return null;
    }
  }

  void addCategory(String name) {
    final newCategory = Category(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    _categories.add(newCategory);
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void adjustStock(String productId, int newStock) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _products[index].stock = newStock;
      notifyListeners();
    }
  }
}
