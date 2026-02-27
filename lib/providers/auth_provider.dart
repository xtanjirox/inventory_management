import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
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
      _hasExistingUsers = false; // WelcomeScreen shown by default; auth state drives navigation
      
      final session = _client.auth.currentSession;
      if (session != null) {
        await _fetchUserProfile(session.user.id);
      }
      
      // Listen to auth state changes
      _client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null && _currentUser?.id != session.user.id) {
          _fetchUserProfile(session.user.id);
        } else if (session == null) {
          _currentUser = null;
          notifyListeners();
        }
      });
      
    } catch (e) {
      _error = 'Failed to restore session: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final authUser = _client.auth.currentUser;

      if (data != null) {
        _currentUser = UserProfile(
          id: data['id'],
          email: data['email'] ?? authUser?.email ?? '',
          name: data['name'] ?? authUser?.email?.split('@').first ?? '',
          passwordHash: '',
          plan: (data['plan_type'] == 'pro') ? AppPlan.pro : AppPlan.normal,
          currency: data['currency'] ?? 'USD',
          language: data['language'] ?? 'en',
        );
      } else if (authUser != null) {
        // Profile row not yet created by trigger — build from auth user
        _currentUser = UserProfile(
          id: authUser.id,
          email: authUser.email ?? '',
          name: authUser.userMetadata?['name'] as String? ??
              authUser.email?.split('@').first ?? '',
          passwordHash: '',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
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

      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (res.user == null) return 'Signup failed. Please try again.';

      if (res.session == null) {
        // Email confirmation is enabled in Supabase — inform the user
        return 'confirm_email';
      }

      // Session active immediately (email confirmation disabled)
      await _fetchUserProfile(res.user!.id);
      return null;
    } on AuthException catch (e) {
      return e.message;
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

      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (res.user != null) {
        await _fetchUserProfile(res.user!.id);
        return null; // success
      }
      return 'Login failed';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
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
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (currency != null) updates['currency'] = currency;
      if (language != null) updates['language'] = language;
      
      await _client.from('profiles').update(updates).eq('id', _currentUser!.id);
      
      _currentUser = _currentUser!.copyWith(
        name: name,
        currency: currency,
        language: language,
      );
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
      // Supabase handles password change via auth.updateUser
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Password change failed: $e';
    }
  }

  Future<String?> upgradeToPro() async {
    if (_currentUser == null) return 'Not authenticated';
    try {
      await _client.from('profiles').update({'plan_type': 'pro'}).eq('id', _currentUser!.id);
      _currentUser = _currentUser!.copyWith(plan: AppPlan.pro);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Upgrade failed: $e';
    }
  }

  // ── App settings persistence ───────────────────────────────────────────────

  Future<String?> getSetting(String key) => _repo.getSetting(key);
  Future<void> setSetting(String key, String value) =>
      _repo.setSetting(key, value);
}
