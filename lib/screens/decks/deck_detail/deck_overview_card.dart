import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Resumen W-L-T + premios de un mazo (issue #118: promocionada desde
/// _buildOverviewCard de deck_detail_screen.dart a un widget de verdad).
class DeckOverviewCard extends StatelessWidget {
  final Map<String, dynamic> overview;
  final String deckFormat;

  /// Racha actual (issue #127): 'win'/'loss'/'tie', o null si no hay
  /// partidas suficientes para determinarla.
  final String? streakType;
  final int streakCount;

  const DeckOverviewCard({
    super.key,
    required this.overview,
    required this.deckFormat,
    this.streakType,
    this.streakCount = 0,
  });

  String get _streakLabel {
    final noun = switch (streakType) {
      'win' => 'victoria',
      'loss' => 'derrota',
      _ => 'empate',
    };
    final plural = streakCount == 1 ? '' : 's';
    return '$streakCount $noun$plural seguida$plural';
  }

  Color _streakColor() {
    switch (streakType) {
      case 'win':
        return AppColors.success;
      case 'loss':
        return AppColors.error;
      default:
        return AppColors.muted;
    }
  }

  String get _streakEmoji {
    switch (streakType) {
      case 'win':
        return '🔥';
      case 'loss':
        return '🥶';
      default:
        return '➖';
    }
  }

  Widget _statColumn(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: AppSizes.spacingXS),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final winRate = overview['winRate'] ?? 0;
    final totalMatches = overview['totalMatches'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$deckFormat · $totalMatches partidas',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (streakType != null && streakCount > 0) ...[
              const SizedBox(height: AppSizes.spacingXS),
              Row(
                children: [
                  Text(_streakEmoji, style: const TextStyle(fontSize: AppSizes.textM)),
                  const SizedBox(width: AppSizes.spacingXS),
                  Text(
                    _streakLabel,
                    style: TextStyle(fontWeight: FontWeight.w600, color: _streakColor()),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(context, '$winRate%', 'Win rate', AppColors.primaryVariant),
                _statColumn(context, '${overview['wins']}', 'Victorias', AppColors.success),
                _statColumn(context, '${overview['losses']}', 'Derrotas', AppColors.error),
                _statColumn(context, '${overview['ties']}', 'Empates', AppColors.muted),
              ],
            ),
            if (totalMatches > 0) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn(
                    context,
                    '${overview['totalUserPrizes']}',
                    'Premios cogidos',
                    Theme.of(context).colorScheme.onSurface,
                  ),
                  _statColumn(
                    context,
                    '${overview['totalOpponentPrizes']}',
                    'Premios cedidos',
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
