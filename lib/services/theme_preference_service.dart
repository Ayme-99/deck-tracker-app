import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferencia de tema persistida (issue #129): claro/oscuro/sistema.
///
/// Notifier global simple en vez de un gestor de estado externo -- el
/// proyecto no usa ninguno (provider esta en pubspec pero sin uso real en
/// ningun sitio) -- para que DeckTrackerApp pueda reconstruir el
/// MaterialApp cuando cambia, sin acoplar quien lo cambia (ej. HomeScreen)
/// con el widget raiz.
class ThemePreferenceService {
  static const _storageKey = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  /// DeckTrackerApp escucha esto (ValueListenableBuilder) para reconstruir
  /// el MaterialApp con el themeMode actual.
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  /// Carga la preferencia guardada, si hay alguna. Se llama una vez al
  /// arrancar la app, antes de runApp, para no mostrar un flash del tema
  /// por defecto (sistema) si el usuario ya habia elegido uno fijo.
  static Future<void> load() async {
    final stored = await _storage.read(key: _storageKey);
    themeMode.value = _fromStorageValue(stored);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _storage.write(key: _storageKey, value: _toStorageValue(mode));
  }

  static ThemeMode _fromStorageValue(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toStorageValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
