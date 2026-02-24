class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });
}

class Warehouse {
  final String id;
  final String name;
  final String location;

  Warehouse({
    required this.id,
    required this.name,
    required this.location,
  });
}

class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String warehouseId;
  final String sku;
  final double price;
  int stock;
  final int lowStockThreshold;
  final String supplier;
  final String? imageUrl; // Optional, defaults to null

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.warehouseId,
    required this.sku,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    this.supplier = 'Unknown',
    this.imageUrl,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? warehouseId,
    String? sku,
    double? price,
    int? stock,
    int? lowStockThreshold,
    String? supplier,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      warehouseId: warehouseId ?? this.warehouseId,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      supplier: supplier ?? this.supplier,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
