import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import 'stats_service.dart';
import '../l10n/app_localizations.dart';

/// Aviso de racha negativa (issue #167): comprueba la racha actual de un
/// mazo tras registrar una partida y, si son 3 o más derrotas seguidas,
/// muestra un SnackBar destacado -- contrapunto al badge de racha positiva
/// ya existente en el detalle de mazo (issue #127), que solo se ve si se
/// entra a esa pantalla.
///
/// Aviso dentro de la app en vez de notificación del sistema: no requiere
/// permisos nuevos ni configuración específica de plataforma, y llega en el
/// momento justo (justo tras registrar la partida que la provoca).
class LosingStreakService {
  static const threshold = 3;

  final _statsService = StatsService();

  /// Consulta best-effort: si falla, no interrumpe el flujo normal de
  /// registrar una partida.
  Future<void> checkAndWarn(BuildContext context, String deckId) async {
    try {
      final streak = await _statsService.getDeckStreak(deckId);
      final streakType = streak['streakType'] as String?;
      final streakCount = streak['streakCount'] as int? ?? 0;

      if (streakType != 'loss' || streakCount < threshold || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(AppLocalizations.of(context).losingStreakWarning(streakCount)),
        ),
      );
    } catch (_) {
      // Sin conexion o error puntual: la partida ya se registro igualmente.
    }
  }
}
