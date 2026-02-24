import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  final UserRepository _repo;

  UserProfile? _currentUser;
  bool _isLoading = true;
  bool _hasExistingUsers = false;
  String? _error;

  AuthProvider({UserRepository? repo})
      : _repo = repo ?? UserRepository() {
    _initialize();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get hasExistingUsers => _hasExistingUsers;
  String? get error => _error;
  AppPlan get plan => _currentUser?.plan ?? AppPlan.normal;
  bool get isPro => plan == AppPlan.pro;

  Future<void> _initialize() async {
    try {
      _hasExistingUsers = await _repo.hasAnyUser();
      final sessionUserId = await _repo.getSessionUserId();
      if (sessionUserId != null) {
        _currentUser = await _repo.getById(sessionUserId);
      }
    } catch (e) {
      _error = 'Failed to restore session: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Auth operations ────────────────────────────────────────────────────────

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _error = null;
      if (name.trim().isEmpty) return 'Name is required';
      if (email.trim().isEmpty) return 'Email is required';
      if (password.length < 6) return 'Password must be at least 6 characters';

      final exists = await _repo.emailExists(email);
      if (exists) return 'An account with this email already exists';

      final user = await _repo.create(
        name: name,
        email: email,
        password: password,
      );
      await _repo.saveSession(user.id);
      _currentUser = user;
      _hasExistingUsers = true;
      notifyListeners();
      return null; // success
    } catch (e) {
      return 'Signup failed: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _error = null;
      if (email.trim().isEmpty) return 'Email is required';
      if (password.isEmpty) return 'Password is required';

      final user = await _repo.login(email, password);
      if (user == null) return 'Invalid email or password';

      await _repo.saveSession(user.id);
      _currentUser = user;
      notifyListeners();
      return null; // success
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> logout() async {
    await _repo.clearSession();
    _currentUser = null;
    notifyListeners();
  }

  // ── Profile updates ────────────────────────────────────────────────────────

  Future<String?> updateProfile({
    String? name,
    String? currency,
    String? language,
  }) async {
    if (_currentUser == null) return 'Not authenticated';
    try {
      final updated = await _repo.update(
        _currentUser!.copyWith(
          name: name,
          currency: currency,
          language: language,
        ),
      );
      _currentUser = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Update failed: $e';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return 'Not authenticated';
    try {
      if (newPassword.length < 6) return 'Password must be at least 6 characters';
      final currentHash = UserRepository.hashPassword(currentPassword);
      if (currentHash != _currentUser!.passwordHash) {
        return 'Current password is incorrect';
      }
      final updated = await _repo.update(
        _currentUser!.copyWith(
          passwordHash: UserRepository.hashPassword(newPassword),
        ),
      );
      _currentUser = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Password change failed: $e';
    }
  }

  Future<String?> upgradeToPro() async {
    if (_currentUser == null) return 'Not authenticated';
    try {
      final upgraded = await _repo.upgradeToPro(_currentUser!.id);
      _currentUser = upgraded;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Upgrade failed: $e';
    }
  }
}
