import 'package:sqflite/sqflite.dart';
import '../../models/models.dart';

class CategoryDao {
  static const String table = 'categories';

  Future<List<Category>> getAll(Database db) async {
    final rows = await db.query(
      table,
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(Database db, String id) async {
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<void> insert(Database db, Category category) async {
    await db.insert(
      table,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Database db, Category category) async {
    await db.update(
      table,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
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

  Future<List<Category>> getUnsynced(Database db) async {
    final rows = await db.query(table, where: 'is_synced = 0');
    return rows.map(Category.fromMap).toList();
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
