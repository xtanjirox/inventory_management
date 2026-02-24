import '../database/app_database.dart';
import '../database/daos/product_dao.dart';
import '../models/models.dart';

class ProductRepository {
  final AppDatabase _db;
  final ProductDao _dao;

  ProductRepository({AppDatabase? db, ProductDao? dao})
      : _db = db ?? AppDatabase.instance,
        _dao = dao ?? ProductDao();

  Future<List<Product>> getAll() async {
    final db = await _db.database;
    return _dao.getAll(db);
  }

  Future<Product?> getById(String id) async {
    final db = await _db.database;
    return _dao.getById(db, id);
  }

  Future<Product?> getBySku(String sku) async {
    final db = await _db.database;
    return _dao.getBySku(db, sku);
  }

  Future<List<Product>> getLowStock() async {
    final db = await _db.database;
    return _dao.getLowStock(db);
  }

  Future<Product> insert(Product product) async {
    final db = await _db.database;
    final toInsert = product.copyWith(isSynced: false);
    await _dao.insert(db, toInsert);
    return toInsert;
  }

  Future<Product> update(Product product) async {
    final db = await _db.database;
    final toUpdate = product.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _dao.update(db, toUpdate);
    return toUpdate;
  }

  Future<Product> adjustStock(Product product, int newStock) async {
    final db = await _db.database;
    await _dao.updateStock(db, product.id, newStock);
    return product.copyWith(stock: newStock, isSynced: false);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await _dao.softDelete(db, id);
  }

  Future<List<Product>> getUnsynced() async {
    final db = await _db.database;
    return _dao.getUnsynced(db);
  }

  Future<void> markSynced(String id, String remoteId) async {
    final db = await _db.database;
    await _dao.markSynced(db, id, remoteId);
  }
}
