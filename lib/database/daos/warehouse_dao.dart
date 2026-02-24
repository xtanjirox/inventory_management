import 'package:sqflite/sqflite.dart';
import '../../models/models.dart';

class WarehouseDao {
  static const String table = 'warehouses';

  Future<List<Warehouse>> getAll(Database db) async {
    final rows = await db.query(
      table,
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(Warehouse.fromMap).toList();
  }

  Future<Warehouse?> getById(Database db, String id) async {
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Warehouse.fromMap(rows.first);
  }

  Future<void> insert(Database db, Warehouse warehouse) async {
    await db.insert(
      table,
      warehouse.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Database db, Warehouse warehouse) async {
    await db.update(
      table,
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
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

  Future<List<Warehouse>> getUnsynced(Database db) async {
    final rows = await db.query(table, where: 'is_synced = 0');
    return rows.map(Warehouse.fromMap).toList();
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
