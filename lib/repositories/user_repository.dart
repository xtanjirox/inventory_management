import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../database/app_database.dart';
import '../database/daos/user_dao.dart';
import '../models/user_profile.dart';

class UserRepository {
  static const String _sessionKey = 'current_user_id';

  final AppDatabase _db;
  final UserDao _dao;

  UserRepository({AppDatabase? db, UserDao? dao})
      : _db = db ?? AppDatabase.instance,
        _dao = dao ?? UserDao();

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<UserProfile?> getById(String id) async {
    final db = await _db.database;
    return _dao.getById(db, id);
  }

  Future<UserProfile?> getByEmail(String email) async {
    final db = await _db.database;
    return _dao.getByEmail(db, email);
  }

  Future<bool> emailExists(String email) async {
    final db = await _db.database;
    return _dao.emailExists(db, email);
  }

  Future<bool> hasAnyUser() async {
    final db = await _db.database;
    final all = await _dao.getAll(db);
    return all.isNotEmpty;
  }

  Future<UserProfile> create({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await _db.database;
    final user = UserProfile(
      name: name.trim(),
      email: email.toLowerCase().trim(),
      passwordHash: hashPassword(password),
    );
    await _dao.insert(db, user);
    return user;
  }

  Future<UserProfile?> login(String email, String password) async {
    final db = await _db.database;
    final user = await _dao.getByEmail(db, email.toLowerCase().trim());
    if (user == null) return null;
    if (user.passwordHash != hashPassword(password)) return null;
    return user;
  }

  Future<UserProfile> update(UserProfile user) async {
    final db = await _db.database;
    final updated = user.copyWith(updatedAt: DateTime.now());
    await _dao.update(db, updated);
    return updated;
  }

  Future<UserProfile> upgradeToPro(String userId) async {
    final db = await _db.database;
    final user = await _dao.getById(db, userId);
    if (user == null) throw Exception('User not found');
    final upgraded = user.copyWith(plan: AppPlan.pro);
    await _dao.update(db, upgraded);
    return upgraded;
  }

  // ── Session persistence ────────────────────────────────────────────────────

  Future<void> saveSession(String userId) async {
    final db = await _db.database;
    await _dao.setSetting(db, _sessionKey, userId);
  }

  Future<String?> getSessionUserId() async {
    final db = await _db.database;
    return _dao.getSetting(db, _sessionKey);
  }

  Future<void> clearSession() async {
    final db = await _db.database;
    await _dao.deleteSetting(db, _sessionKey);
  }

  // ── Generic app settings (key-value) ──────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await _db.database;
    return _dao.getSetting(db, key);
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db.database;
    await _dao.setSetting(db, key, value);
  }
}
