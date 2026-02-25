import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ProductVariant {
  final String id;
  final String name;
  final String? sku;
  final double? price;
  final int stock;

  ProductVariant({
    String? id,
    required this.name,
    this.sku,
    this.price,
    this.stock = 0,
  }) : id = (id == null || id.isEmpty) ? _uuid.v4() : id;

  ProductVariant copyWith({
    String? name,
    String? sku,
    double? price,
    int? stock,
  }) {
    return ProductVariant(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sku': sku,
        'price': price,
        'stock': stock,
      };

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
        id: map['id'] as String? ?? '',
        name: map['name'] as String,
        sku: map['sku'] as String?,
        price: (map['price'] as num?)?.toDouble(),
        stock: map['stock'] as int? ?? 0,
      );

  static String encodeList(List<ProductVariant> variants) =>
      jsonEncode(variants.map((v) => v.toMap()).toList());

  static List<ProductVariant> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((m) => ProductVariant.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
