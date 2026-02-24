import 'package:sqflite/sqflite.dart';
import '../../models/user_profile.dart';

class UserDao {
  static const String table = 'users';
  static const String settingsTable = 'local_settings';

  Future<List<UserProfile>> getAll(Database db) async {
    final rows = await db.query(table, orderBy: 'created_at ASC');
    return rows.map(UserProfile.fromMap).toList();
  }

  Future<UserProfile?> getById(Database db, String id) async {
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<UserProfile?> getByEmail(Database db, String email) async {
    final rows = await db.query(
      table,
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<bool> emailExists(Database db, String email) async {
    final rows = await db.query(
      table,
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    return rows.isNotEmpty;
  }

  Future<void> insert(Database db, UserProfile user) async {
    await db.insert(
      table,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(Database db, UserProfile user) async {
    await db.update(
      table,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ── Local settings (key-value session store) ───────────────────────────────

  Future<String?> getSetting(Database db, String key) async {
    final rows = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(Database db, String key, String value) async {
    await db.insert(
      settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSetting(Database db, String key) async {
    await db.delete(settingsTable, where: 'key = ?', whereArgs: [key]);
  }
}
