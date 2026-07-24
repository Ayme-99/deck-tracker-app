/// Formatea la linea de estado del widget de acceso rapido Nivel 2 (issue
/// #132): la racha actual del mazo mas jugado. Logica pura, separada de
/// QuickWidgetSyncService, para poder testearla sin depender de home_widget.
class QuickWidgetStatusFormatter {
  QuickWidgetStatusFormatter._();

  static String _streakEmoji(String? streakType) {
    switch (streakType) {
      case 'win':
        return '🔥';
      case 'loss':
        return '🥶';
      default:
        return '➖';
    }
  }

  /// Devuelve la etiqueta de racha (ej. "🔥 3V seguidas"), o cadena vacia si
  /// no hay racha que mostrar (sin partidas, o streakCount 0).
  static String formatStreakLabel(String? streakType, int streakCount) {
    if (streakType == null || streakCount <= 0) return '';

    final noun = switch (streakType) {
      'win' => 'V',
      'loss' => 'D',
      _ => 'E',
    };
    final plural = streakCount == 1 ? '' : 's';
    return '${_streakEmoji(streakType)} $streakCount$noun seguida$plural';
  }
}
