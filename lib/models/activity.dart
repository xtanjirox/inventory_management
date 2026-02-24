import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ActivityType {
  productAdded,
  productDeleted,
  restock,
  stockAdjustment,
  returnToStock,
  damagedArticle,
  sale,
}

extension ActivityTypeExt on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.productAdded:
        return 'Product Added';
      case ActivityType.productDeleted:
        return 'Product Deleted';
      case ActivityType.restock:
        return 'Restock';
      case ActivityType.stockAdjustment:
        return 'Stock Adjustment';
      case ActivityType.returnToStock:
        return 'Return to Stock';
      case ActivityType.damagedArticle:
        return 'Damaged Article';
      case ActivityType.sale:
        return 'Sale';
    }
  }
}

class Activity {
  final String id;
  final ActivityType type;
  final String productId;
  final String productName;
  final int? quantityChange;
  final String? note;
  final String userId;
  final DateTime timestamp;

  Activity({
    String? id,
    required this.type,
    required this.productId,
    required this.productName,
    this.quantityChange,
    this.note,
    required this.userId,
    DateTime? timestamp,
  })  : id = (id == null || id.isEmpty) ? _uuid.v4() : id,
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'product_id': productId,
        'product_name': productName,
        'quantity_change': quantityChange,
        'note': note,
        'user_id': userId,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
        id: map['id'] as String,
        type: ActivityType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => ActivityType.stockAdjustment,
        ),
        productId: map['product_id'] as String,
        productName: map['product_name'] as String,
        quantityChange: map['quantity_change'] as int?,
        note: map['note'] as String?,
        userId: map['user_id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}
