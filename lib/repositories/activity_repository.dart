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
