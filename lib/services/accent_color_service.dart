import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../styles/colors.dart';
import '../l10n/app_localizations.dart';

/// Color de acento personalizable (issue #168): mas alla del claro/oscuro/
/// sistema (issue #129), el usuario puede elegir el color principal de la
/// app entre una paleta fija. Persistido igual que la preferencia de tema
/// (flutter_secure_storage).
///
/// Reasigna directamente AppColors.primary (ver comentario en colors.dart)
/// en vez de solo pasar el color al ThemeData: muchos widgets ya existentes
/// usan AppColors.primary directamente, no Theme.of(context).colorScheme.
/// primary, asi que es la unica forma de que el cambio se refleje en toda
/// la app sin reescribirlos todos.
class AccentColorService {
  AccentColorService._();

  static const _storageKey = 'accent_color';
  static const _storage = FlutterSecureStorage();
  static const _defaultKey = 'blue';

  /// Paleta fija de acentos seleccionables. 'blue' es el azul original de
  /// la app (AppColors.primary de siempre), el resto son alternativas.
  static const Map<String, Color> palette = {
    'blue': Color(0xFF1E88E5),
    'purple': Color(0xFF8E24AA),
    'green': Color(0xFF43A047),
    'red': Color(0xFFE53935),
    'teal': Color(0xFF00897B),
    'orange': Color(0xFFFB8C00),
  };

  static Map<String, String> labelsFor(AppLocalizations l10n) => {
    'blue': l10n.accentColorBlue,
    'purple': l10n.accentColorPurple,
    'green': l10n.accentColorGreen,
    'red': l10n.accentColorRed,
    'teal': l10n.accentColorTeal,
    'orange': l10n.accentColorOrange,
  };

  /// DeckTrackerApp escucha esto para reconstruir el MaterialApp (el tema
  /// se calcula a partir de AppColors.primary en buildAppTheme).
  static final ValueNotifier<String> accentKey = ValueNotifier(_defaultKey);

  static Future<void> load() async {
    final stored = await _storage.read(key: _storageKey);
    final key = palette.containsKey(stored) ? stored! : _defaultKey;
    accentKey.value = key;
    AppColors.primary = palette[key]!;
  }

  static Future<void> setAccent(String key) async {
    if (!palette.containsKey(key)) return;
    accentKey.value = key;
    AppColors.primary = palette[key]!;
    await _storage.write(key: _storageKey, value: key);
  }
}
