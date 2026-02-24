import 'package:sqflite/sqflite.dart';
import '../../models/models.dart';

class ProductDao {
  static const String table = 'products';

  Future<List<Product>> getAll(Database db) async {
    final rows = await db.query(
      table,
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getByCategory(Database db, String categoryId) async {
    final rows = await db.query(
      table,
      where: 'deleted_at IS NULL AND category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getByWarehouse(Database db, String warehouseId) async {
    final rows = await db.query(
      table,
      where: 'deleted_at IS NULL AND warehouse_id = ?',
      whereArgs: [warehouseId],
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(Database db, String id) async {
    final rows = await db.query(
      table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product?> getBySku(Database db, String sku) async {
    final rows = await db.query(
      table,
      where: 'sku = ? AND deleted_at IS NULL',
      whereArgs: [sku],
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> getLowStock(Database db) async {
    final rows = await db.rawQuery(
      'SELECT * FROM $table WHERE deleted_at IS NULL AND stock <= low_stock_threshold ORDER BY stock ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<void> insert(Database db, Product product) async {
    await db.insert(
      table,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Database db, Product product) async {
    await db.update(
      table,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> updateStock(Database db, String id, int newStock) async {
    await db.update(
      table,
      {
        'stock': newStock,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDelete(Database db, String id) async {
    await db.update(
      table,
      {
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getUnsynced(Database db) async {
    final rows = await db.query(table, where: 'is_synced = 0');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> markSynced(Database db, String id, String remoteId) async {
    await db.update(
      table,
      {'is_synced': 1, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
