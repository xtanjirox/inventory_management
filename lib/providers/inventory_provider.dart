import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/activity.dart';
import '../repositories/category_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/activity_repository.dart';

class InventoryProvider with ChangeNotifier {
  final CategoryRepository _categoryRepo;
  final WarehouseRepository _warehouseRepo;
  final ProductRepository _productRepo;
  final ActivityRepository _activityRepo;

  List<Category> _categories = [];
  List<Warehouse> _warehouses = [];
  List<Product> _products = [];
  List<Activity> _recentActivities = [];

  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Category> get categories => [..._categories];
  List<Warehouse> get warehouses => [..._warehouses];
  List<Product> get products => [..._products];
  List<Activity> get recentActivities => [..._recentActivities];
  List<Product> get lowStockProducts =>
      _products.where((p) => p.stock <= p.lowStockThreshold).toList();

  String? _currentUserId;

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  InventoryProvider({
    CategoryRepository? categoryRepo,
    WarehouseRepository? warehouseRepo,
    ProductRepository? productRepo,
    ActivityRepository? activityRepo,
  })  : _categoryRepo = categoryRepo ?? CategoryRepository(),
        _warehouseRepo = warehouseRepo ?? WarehouseRepository(),
        _productRepo = productRepo ?? ProductRepository(),
        _activityRepo = activityRepo ?? ActivityRepository() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      _categories = await _categoryRepo.getAll();
      _warehouses = await _warehouseRepo.getAll();
      _products = await _productRepo.getAll();
      _recentActivities = await _activityRepo.getRecent(limit: 20);

      // Seed default data on first launch
      if (_categories.isEmpty) {
        await _seedDefaultData();
      }
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _seedDefaultData() async {
    final defaultCategories = [
      Category(name: 'Electronics'),
      Category(name: 'Clothing'),
      Category(name: 'Food'),
      Category(name: 'Other'),
    ];
    for (final c in defaultCategories) {
      final inserted = await _categoryRepo.insert(c);
      _categories.add(inserted);
    }

    final defaultWarehouses = [
      Warehouse(name: 'Main Warehouse', location: 'New York, NY'),
      Warehouse(name: 'West Coast Hub', location: 'Los Angeles, CA'),
    ];
    for (final w in defaultWarehouses) {
      final inserted = await _warehouseRepo.insert(w);
      _warehouses.add(inserted);
    }

    if (_categories.isNotEmpty && _warehouses.isNotEmpty) {
      final defaultProducts = [
        Product(
          name: 'Wireless Headphones',
          description: 'High-quality wireless headphones with noise cancellation.',
          categoryId: _categories[0].id,
          warehouseId: _warehouses[0].id,
          sku: 'WH-1001',
          price: 129.99,
          stock: 45,
          lowStockThreshold: 10,
          supplier: 'AudioTech Inc.',
          imageUrl:
              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&auto=format&fit=crop&q=60',
        ),
        Product(
          name: 'Cotton T-Shirt',
          description: 'Comfortable 100% cotton t-shirt.',
          categoryId: _categories[1].id,
          warehouseId: _warehouses[1].id,
          sku: 'TS-2001',
          price: 19.99,
          stock: 120,
          lowStockThreshold: 20,
          supplier: 'Apparel Co.',
          imageUrl:
              'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500&auto=format&fit=crop&q=60',
        ),
        Product(
          name: 'Smart Watch',
          description: 'Fitness tracking smartwatch with heart rate monitor.',
          categoryId: _categories[0].id,
          warehouseId: _warehouses[0].id,
          sku: 'SW-1002',
          price: 199.99,
          stock: 15,
          lowStockThreshold: 20,
          supplier: 'TechGear',
          imageUrl:
              'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=500&auto=format&fit=crop&q=60',
        ),
      ];
      for (final p in defaultProducts) {
        final inserted = await _productRepo.insert(p);
        _products.add(inserted);
      }
    }
  }

  // ── Lookups ────────────────────────────────────────────────────────────────

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Warehouse? getWarehouseById(String id) {
    try {
      return _warehouses.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id || p.sku == id);
    } catch (_) {
      return null;
    }
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<void> addCategory(String name) async {
    final newCategory = Category(name: name);
    // Optimistic update
    _categories.add(newCategory);
    notifyListeners();
    // Persist
    await _categoryRepo.insert(newCategory);
  }

  // ── Products ───────────────────────────────────────────────────────────────

  Future<void> addProduct(Product product) async {
    _products.insert(0, product);
    notifyListeners();
    await _productRepo.insert(product);
    await _logActivity(
      type: ActivityType.productAdded,
      productId: product.id,
      productName: product.name,
      quantityChange: product.stock,
    );
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      notifyListeners();
      await _productRepo.update(product);
    }
  }

  Future<void> deleteProduct(String id) async {
    final product = _products.firstWhere((p) => p.id == id,
        orElse: () => Product(
            name: 'Unknown',
            categoryId: '',
            warehouseId: '',
            sku: '',
            price: 0,
            stock: 0,
            lowStockThreshold: 0));
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    await _productRepo.delete(id);
    await _logActivity(
      type: ActivityType.productDeleted,
      productId: id,
      productName: product.name,
    );
  }

  Future<void> adjustStock(
    String productId,
    int newStock, {
    ActivityType type = ActivityType.stockAdjustment,
    String? note,
  }) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      final oldStock = _products[index].stock;
      _products[index] = _products[index].copyWith(stock: newStock);
      notifyListeners();
      await _productRepo.adjustStock(_products[index], newStock);
      await _logActivity(
        type: type,
        productId: productId,
        productName: _products[index].name,
        quantityChange: newStock - oldStock,
        note: note,
      );
    }
  }

  Future<void> _logActivity({
    required ActivityType type,
    required String productId,
    required String productName,
    int? quantityChange,
    String? note,
  }) async {
    final activity = Activity(
      type: type,
      productId: productId,
      productName: productName,
      userId: _currentUserId ?? 'local',
      quantityChange: quantityChange,
      note: note,
    );
    await _activityRepo.insert(activity);
    _recentActivities.insert(0, activity);
    if (_recentActivities.length > 20) {
      _recentActivities = _recentActivities.take(20).toList();
    }
    notifyListeners();
  }

  // ── Refresh (pull latest from DB) ──────────────────────────────────────────

  Future<void> refresh() async {
    _categories = await _categoryRepo.getAll();
    _warehouses = await _warehouseRepo.getAll();
    _products = await _productRepo.getAll();
    _recentActivities = await _activityRepo.getRecent(limit: 20);
    notifyListeners();
  }
}

