import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/sync_service.dart';
import '../repositories/category_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/activity_repository.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncPendingCounts {
  final int categories;
  final int warehouses;
  final int products;
  final int activities;

  const SyncPendingCounts({
    this.categories = 0,
    this.warehouses = 0,
    this.products = 0,
    this.activities = 0,
  });

  int get total => categories + warehouses + products + activities;
}

class SyncProvider with ChangeNotifier {
  final SupabaseSyncService _service;
  final CategoryRepository _categoryRepo;
  final WarehouseRepository _warehouseRepo;
  final ProductRepository _productRepo;
  final ActivityRepository _activityRepo;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncedAt;
  String? _lastError;
  SyncPendingCounts _pending = const SyncPendingCounts();
  bool _autoSync = false;

  SyncProvider({
    SupabaseSyncService? service,
    CategoryRepository? categoryRepo,
    WarehouseRepository? warehouseRepo,
    ProductRepository? productRepo,
    ActivityRepository? activityRepo,
  })  : _service = service ?? SupabaseSyncService(),
        _categoryRepo = categoryRepo ?? CategoryRepository(),
        _warehouseRepo = warehouseRepo ?? WarehouseRepository(),
        _productRepo = productRepo ?? ProductRepository(),
        _activityRepo = activityRepo ?? ActivityRepository() {
    _loadPrefs();
  }

  SyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;
  SyncPendingCounts get pending => _pending;
  bool get autoSync => _autoSync;
  bool get isSyncing => _status == SyncStatus.syncing;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSync = prefs.getBool('cloud_auto_sync') ?? false;
    final savedMs = prefs.getInt('cloud_last_synced_ms');
    if (savedMs != null) {
      _lastSyncedAt = DateTime.fromMillisecondsSinceEpoch(savedMs);
    }
    notifyListeners();
    await refreshPendingCounts();
  }

  Future<void> refreshPendingCounts() async {
    try {
      final cats = await _categoryRepo.getUnsynced();
      final whs = await _warehouseRepo.getUnsynced();
      final prods = await _productRepo.getUnsynced();
      final acts = await _activityRepo.getUnsyncedActivities();
      _pending = SyncPendingCounts(
        categories: cats.length,
        warehouses: whs.length,
        products: prods.length,
        activities: acts.length,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('SyncProvider.refreshPendingCounts error: $e');
    }
  }

  Future<void> syncAll() async {
    if (_status == SyncStatus.syncing) return;
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      await _service.syncAll();
      _lastSyncedAt = DateTime.now();
      _status = SyncStatus.success;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'cloud_last_synced_ms', _lastSyncedAt!.millisecondsSinceEpoch);
      await refreshPendingCounts();
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
      notifyListeners();
    }
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_auto_sync', value);
    notifyListeners();
  }
}
