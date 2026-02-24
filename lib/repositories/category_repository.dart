import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../models/models.dart';

class CategoryRepository {
  final AppDatabase _db;
  final CategoryDao _dao;

  CategoryRepository({AppDatabase? db, CategoryDao? dao})
      : _db = db ?? AppDatabase.instance,
        _dao = dao ?? CategoryDao();

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    return _dao.getAll(db);
  }

  Future<Category?> getById(String id) async {
    final db = await _db.database;
    return _dao.getById(db, id);
  }

  Future<Category> insert(Category category) async {
    final db = await _db.database;
    final toInsert = category.copyWith(isSynced: false);
    await _dao.insert(db, toInsert);
    return toInsert;
  }

  Future<Category> update(Category category) async {
    final db = await _db.database;
    final toUpdate = category.copyWith(
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

  Future<List<Category>> getUnsynced() async {
    final db = await _db.database;
    return _dao.getUnsynced(db);
  }

  Future<void> markSynced(String id, String remoteId) async {
    final db = await _db.database;
    await _dao.markSynced(db, id, remoteId);
  }
}
