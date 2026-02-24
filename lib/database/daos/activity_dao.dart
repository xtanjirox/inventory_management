import 'package:sqflite/sqflite.dart';
import '../../models/activity.dart';

class ActivityDao {
  static const String table = 'activities';

  Future<List<Activity>> getRecent(Database db,
      {int limit = 20, String? userId}) async {
    final rows = await db.query(
      table,
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(Activity.fromMap).toList();
  }

  Future<List<Activity>> getByProductId(Database db, String productId) async {
    final rows = await db.query(
      table,
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(Activity.fromMap).toList();
  }

  Future<void> insert(Database db, Activity activity) async {
    await db.insert(table, activity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteOlderThan(Database db, DateTime cutoff) async {
    await db.delete(
      table,
      where: 'timestamp < ?',
      whereArgs: [cutoff.millisecondsSinceEpoch],
    );
  }
}
