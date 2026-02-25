import 'package:flutter/material.dart';

import '../repositories/user_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final UserRepository _repo;
  ThemeMode _mode = ThemeMode.light;

  ThemeProvider({UserRepository? repo}) : _repo = repo ?? UserRepository() {
    _load();
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> _load() async {
    final saved = await _repo.getSetting('theme_mode');
    _mode = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'system'
            ? ThemeMode.system
            : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final val = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.system
            ? 'system'
            : 'light';
    await _repo.setSetting('theme_mode', val);
  }
}
