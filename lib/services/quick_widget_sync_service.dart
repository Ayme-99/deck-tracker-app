import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'quick_widget_status_formatter.dart';
import 'stats_service.dart';

/// Sincroniza el widget de acceso rapido (issue #10) con datos reales
/// (issue #132): la racha actual del mazo mas jugado.
///
/// home_widget solo tiene implementacion nativa en Android/iOS -- fuera de
/// esas plataformas el canal no existe (ver guardas kIsWeb/Platform.isAndroid
/// ya usadas en main.dart/splash_screen.dart para este mismo plugin).
///
/// El widget es un extra decorativo: si algo falla al sincronizar (sin
/// conexion, sesion caducada...) no debe interrumpir el flujo de la app, asi
/// que los errores se ignoran en silencio.
class QuickWidgetSyncService {
  final _statsService = StatsService();

  static const _androidWidgetName = 'QuickRegisterWidgetProvider';

  Future<void> sync() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final ranking = await _statsService.getDeckRanking(sortBy: 'totalMatches');
      if (ranking.isEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_deck_name', '');
        await HomeWidget.saveWidgetData<String>('widget_streak_label', '');
        await HomeWidget.saveWidgetData<String>('widget_streak_type', '');
        await HomeWidget.updateWidget(androidName: _androidWidgetName);
        return;
      }

      final topDeck = ranking.first as Map<String, dynamic>;
      final deckId = topDeck['deckId'] as String;
      final deckName = topDeck['deckName'] as String;

      final streak = await _statsService.getDeckStreak(deckId);
      final streakType = streak['streakType'] as String?;
      final streakCount = streak['streakCount'] as int? ?? 0;

      final streakLabel = QuickWidgetStatusFormatter.formatStreakLabel(streakType, streakCount);

      await HomeWidget.saveWidgetData<String>('widget_deck_name', deckName);
      await HomeWidget.saveWidgetData<String>('widget_streak_label', streakLabel);
      await HomeWidget.saveWidgetData<String>('widget_streak_type', streakType ?? '');
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (_) {
      // Sincronizacion best-effort: un fallo aqui no debe romper el flujo principal.
    }
  }
}
