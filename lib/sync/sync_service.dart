import '../repositories/category_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/product_repository.dart';

/// Abstract interface for synchronization backends.
/// Implement this with [SupabaseSyncService] once Supabase is configured.
abstract class SyncService {
  Future<void> syncAll();
  Future<void> syncCategories();
  Future<void> syncWarehouses();
  Future<void> syncProducts();
}

/// No-op local sync service. Used when cloud sync is disabled.
/// Replace with [SupabaseSyncService] once the user enables cloud sync.
class LocalSyncService implements SyncService {
  final CategoryRepository _categoryRepo;
  final WarehouseRepository _warehouseRepo;
  final ProductRepository _productRepo;

  LocalSyncService({
    CategoryRepository? categoryRepo,
    WarehouseRepository? warehouseRepo,
    ProductRepository? productRepo,
  })  : _categoryRepo = categoryRepo ?? CategoryRepository(),
        _warehouseRepo = warehouseRepo ?? WarehouseRepository(),
        _productRepo = productRepo ?? ProductRepository();

  @override
  Future<void> syncAll() async {
    await syncCategories();
    await syncWarehouses();
    await syncProducts();
  }

  @override
  Future<void> syncCategories() async {
    // No-op: returns unsynced items for inspection/debugging
    final unsynced = await _categoryRepo.getUnsynced();
    assert(unsynced.isEmpty || true, 'Categories pending sync: ${unsynced.length}');
  }

  @override
  Future<void> syncWarehouses() async {
    final unsynced = await _warehouseRepo.getUnsynced();
    assert(unsynced.isEmpty || true, 'Warehouses pending sync: ${unsynced.length}');
  }

  @override
  Future<void> syncProducts() async {
    final unsynced = await _productRepo.getUnsynced();
    assert(unsynced.isEmpty || true, 'Products pending sync: ${unsynced.length}');
  }
}

// ---------------------------------------------------------------------------
// Stub for future Supabase implementation.
//
// class SupabaseSyncService implements SyncService {
//   final SupabaseClient _client;
//   final CategoryRepository _categoryRepo;
//   final WarehouseRepository _warehouseRepo;
//   final ProductRepository _productRepo;
//
//   SupabaseSyncService(this._client, ...);
//
//   @override
//   Future<void> syncAll() async {
//     await syncCategories();
//     await syncWarehouses();
//     await syncProducts();
//   }
//
//   @override
//   Future<void> syncCategories() async {
//     final unsynced = await _categoryRepo.getUnsynced();
//     for (final cat in unsynced) {
//       await _client.from('categories').upsert(cat.toMap());
//       await _categoryRepo.markSynced(cat.id, cat.id); // use Supabase row id
//     }
//   }
//   // ... same for warehouses and products
// }
// ---------------------------------------------------------------------------
