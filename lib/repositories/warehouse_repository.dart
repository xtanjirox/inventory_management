import '../database/app_database.dart';
import '../database/daos/warehouse_dao.dart';
import '../models/models.dart';

class WarehouseRepository {
  final AppDatabase _db;
  final WarehouseDao _dao;

  WarehouseRepository({AppDatabase? db, WarehouseDao? dao})
      : _db = db ?? AppDatabase.instance,
        _dao = dao ?? WarehouseDao();

  Future<List<Warehouse>> getAll() async {
    final db = await _db.database;
    return _dao.getAll(db);
  }

  Future<Warehouse?> getById(String id) async {
    final db = await _db.database;
    return _dao.getById(db, id);
  }

  Future<Warehouse> insert(Warehouse warehouse) async {
    final db = await _db.database;
    final toInsert = warehouse.copyWith(isSynced: false);
    await _dao.insert(db, toInsert);
    return toInsert;
  }

  Future<Warehouse> update(Warehouse warehouse) async {
    final db = await _db.database;
    final toUpdate = warehouse.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _dao.update(db, toUpdate);
    return toUpdate;
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await _dao.softDelete(db, id);
  }

  Future<List<Warehouse>> getUnsynced() async {
    final db = await _db.database;
    return _dao.getUnsynced(db);
  }

  Future<void> markSynced(String id, String remoteId) async {
    final db = await _db.database;
    await _dao.markSynced(db, id, remoteId);
  }
}
