import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Category {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  final String? remoteId;

  Category({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.isSynced = false,
    this.remoteId,
  })  : id = (id == null || id.isEmpty) ? _uuid.v4() : id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Category copyWith({
    String? name,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isSynced,
    String? remoteId,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
        'is_synced': isSynced ? 1 : 0,
        'remote_id': remoteId,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
        isSynced: (map['is_synced'] as int) == 1,
        remoteId: map['remote_id'] as String?,
      );
}

class Warehouse {
  final String id;
  final String name;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  final String? remoteId;

  Warehouse({
    String? id,
    required this.name,
    required this.location,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.isSynced = false,
    this.remoteId,
  })  : id = (id == null || id.isEmpty) ? _uuid.v4() : id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Warehouse copyWith({
    String? name,
    String? location,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isSynced,
    String? remoteId,
  }) {
    return Warehouse(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
        'is_synced': isSynced ? 1 : 0,
        'remote_id': remoteId,
      };

  factory Warehouse.fromMap(Map<String, dynamic> map) => Warehouse(
        id: map['id'] as String,
        name: map['name'] as String,
        location: map['location'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
        isSynced: (map['is_synced'] as int) == 1,
        remoteId: map['remote_id'] as String?,
      );
}

class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String warehouseId;
  final String sku;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String supplier;
  final String? imageUrl;
  final String? imagePath;
  final String? variantsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  final String? remoteId;

  Product({
    String? id,
    required this.name,
    this.description = '',
    required this.categoryId,
    required this.warehouseId,
    required this.sku,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    this.supplier = '',
    this.imageUrl,
    this.imagePath,
    this.variantsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.isSynced = false,
    this.remoteId,
  })  : id = (id == null || id.isEmpty) ? _uuid.v4() : id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({
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
    String? imagePath,
    bool clearImagePath = false,
    String? variantsJson,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isSynced,
    String? remoteId,
  }) {
    return Product(
      id: id,
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
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      variantsJson: variantsJson ?? this.variantsJson,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category_id': categoryId,
        'warehouse_id': warehouseId,
        'sku': sku,
        'price': price,
        'stock': stock,
        'low_stock_threshold': lowStockThreshold,
        'supplier': supplier,
        'image_url': imageUrl,
        'image_path': imagePath,
        'variants_json': variantsJson,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
        'is_synced': isSynced ? 1 : 0,
        'remote_id': remoteId,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        categoryId: map['category_id'] as String,
        warehouseId: map['warehouse_id'] as String,
        sku: map['sku'] as String,
        price: (map['price'] as num).toDouble(),
        stock: map['stock'] as int,
        lowStockThreshold: map['low_stock_threshold'] as int,
        supplier: map['supplier'] as String? ?? '',
        imageUrl: map['image_url'] as String?,
        imagePath: map['image_path'] as String?,
        variantsJson: map['variants_json'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
        isSynced: (map['is_synced'] as int) == 1,
        remoteId: map['remote_id'] as String?,
      );
}

