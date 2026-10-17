import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _storageKey = 'soul_theme_mode';
  static const _storage = FlutterSecureStorage();

  int _revision = 0;

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == null || saved == 'system') return;
      final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
      if (_revision == 0) state = mode;
    } catch (_) {
      // Keep light mode if the device cannot read the optional setting.
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final revision = ++_revision;
    final previousMode = state;
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    try {
      await _storage.write(key: _storageKey, value: enabled ? 'dark' : 'light');
    } catch (_) {
      if (revision == _revision) state = previousMode;
      rethrow;
    }
  }
}
