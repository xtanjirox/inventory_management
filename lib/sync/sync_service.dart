import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/category_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/activity_repository.dart';

/// Abstract interface for synchronization backends.
abstract class SyncService {
  Future<void> syncAll();
  Future<void> syncCategories();
  Future<void> syncWarehouses();
  Future<void> syncProducts();
  Future<void> syncActivities();
}

/// Supabase implementation of SyncService.
class SupabaseSyncService implements SyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final CategoryRepository _categoryRepo;
  final WarehouseRepository _warehouseRepo;
  final ProductRepository _productRepo;
  final ActivityRepository _activityRepo;

  SupabaseSyncService({
    CategoryRepository? categoryRepo,
    WarehouseRepository? warehouseRepo,
    ProductRepository? productRepo,
    ActivityRepository? activityRepo,
  })  : _categoryRepo = categoryRepo ?? CategoryRepository(),
        _warehouseRepo = warehouseRepo ?? WarehouseRepository(),
        _productRepo = productRepo ?? ProductRepository(),
        _activityRepo = activityRepo ?? ActivityRepository();

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<void> syncAll() async {
    if (_userId == null) return;
    
    // Order matters because of foreign key constraints in Supabase
    // 1. First sync standalone entities (categories, warehouses)
    await syncCategories();
    await syncWarehouses();
    
    // 2. Then sync entities that depend on them (products)
    await syncProducts();
    
    // 3. Finally sync entities that depend on products (activities)
    await syncActivities();
  }

  @override
  Future<void> syncCategories() async {
    if (_userId == null) return;
    try {
      final unsynced = await _categoryRepo.getUnsynced();
      for (final cat in unsynced) {
        final data = cat.toMap();
        data.remove('is_synced');
        data.remove('remote_id');
        data['user_id'] = _userId;
        await _client.from('categories').upsert(data);
        await _categoryRepo.markSynced(cat.id, cat.id);
      }
    } catch (e) {
      debugPrint('Sync categories error: $e');
      throw e; // rethrow so syncAll stops if a dependency fails
    }
  }

  @override
  Future<void> syncWarehouses() async {
    if (_userId == null) return;
    try {
      final unsynced = await _warehouseRepo.getUnsynced();
      for (final wh in unsynced) {
        final data = wh.toMap();
        data.remove('is_synced');
        data.remove('remote_id');
        data['user_id'] = _userId;
        await _client.from('warehouses').upsert(data);
        await _warehouseRepo.markSynced(wh.id, wh.id);
      }
    } catch (e) {
      debugPrint('Sync warehouses error: $e');
      throw e; // rethrow
    }
  }

  @override
  Future<void> syncProducts() async {
    if (_userId == null) return;
    try {
      final unsynced = await _productRepo.getUnsynced();
      for (final prod in unsynced) {
        final data = prod.toMap();
        data.remove('is_synced');
        data.remove('remote_id');
        data['user_id'] = _userId;
        await _client.from('products').upsert(data);
        await _productRepo.markSynced(prod.id, prod.id);
      }
    } catch (e) {
      debugPrint('Sync products error: $e');
      throw e;
    }
  }

  @override
  Future<void> syncActivities() async {
    if (_userId == null) return;
    try {
      final unsynced = await _activityRepo.getUnsyncedActivities();
      for (final act in unsynced) {
        final data = act.toMap();
        data.remove('is_synced');
        data['user_id'] = _userId;
        await _client.from('activities').upsert(data);
        await _activityRepo.markActivitySynced(act.id, act.id);
      }
    } catch (e) {
      debugPrint('Sync activities error: $e');
      throw e;
    }
  }
}
