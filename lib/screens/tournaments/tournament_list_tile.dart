import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/tournament.dart';
import '../../widgets/sprite_avatar_group.dart';

/// Tarjeta de un torneo en el listado (issue #118: extraida de
/// tournaments_screen.dart).
class TournamentListTile extends StatelessWidget {
  final Tournament tournament;
  final Deck? deck;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TournamentListTile({
    super.key,
    required this.tournament,
    required this.deck,
    required this.onTap,
    required this.onLongPress,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _statusChip(String status) {
    final isFinished = status == 'finished';
    return Chip(
      label: Text(isFinished ? 'Finalizado' : 'En curso'),
      backgroundColor: isFinished ? AppColors.muted.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isFinished ? AppColors.muted : AppColors.success,
        fontSize: AppSizes.textXS,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (deck != null) ...[
                SpriteAvatarGroup(
                  sprite1: deck!.sprite1,
                  sprite2: deck!.sprite2,
                  size: AppSizes.iconNormal,
                ),
                const SizedBox(width: AppSizes.spacingM),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      [
                        _formatDate(tournament.date),
                        if (deck != null) deck!.name,
                        if (tournament.structure != null)
                          kTournamentStructureLabels[tournament.structure] ?? tournament.structure!,
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(tournament.status),
                  if (tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      '🏆 ${tournament.finalStanding}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.textXS),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
