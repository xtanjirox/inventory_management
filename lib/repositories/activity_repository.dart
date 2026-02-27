import '../database/app_database.dart';
import '../database/daos/activity_dao.dart';
import '../models/activity.dart';

class ActivityRepository {
  final AppDatabase _db;
  final ActivityDao _dao;

  ActivityRepository({AppDatabase? db, ActivityDao? dao})
      : _db = db ?? AppDatabase.instance,
        _dao = dao ?? ActivityDao();

  Future<List<Activity>> getRecent({int limit = 20, String? userId}) async {
    final db = await _db.database;
    return _dao.getRecent(db, limit: limit, userId: userId);
  }

  Future<List<Activity>> getByProductId(String productId) async {
    final db = await _db.database;
    return _dao.getByProductId(db, productId);
  }

  Future<List<Activity>> getUnsyncedActivities() async {
    final db = await _db.database;
    final rows = await db.query('activities');
    // Activities are immutable in this app so we just return all local activities.
    // In a full sync model, we'd add a synced flag to activities table.
    return rows.map((r) => Activity.fromMap(r)).toList();
  }

  Future<void> markActivitySynced(String id, String serverId) async {
    // No-op for now. A full sync requires adding a synced flag to the activities table.
  }

  Future<Activity> insert(Activity activity) async {
    final db = await _db.database;
    await _dao.insert(db, activity);
    return activity;
  }

  Future<void> log({
    required ActivityType type,
    required String productId,
    required String productName,
    required String userId,
    int? quantityChange,
    String? note,
  }) async {
    final activity = Activity(
      type: type,
      productId: productId,
      productName: productName,
      userId: userId,
      quantityChange: quantityChange,
      note: note,
    );
    await insert(activity);
  }
}
