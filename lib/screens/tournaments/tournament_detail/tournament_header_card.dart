import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/deck.dart';
import '../../../models/tournament.dart';
import '../../../widgets/sprite_avatar_group.dart';

/// Cabecera del detalle de un torneo tracked (issue #115: extraida de
/// tournament_detail_screen.dart): fecha/mazo, estado, estructura,
/// ubicación, posición final y notas.
class TournamentHeaderCard extends StatelessWidget {
  final Tournament tournament;
  final Deck? deck;
  final VoidCallback onEditFinalStanding;

  const TournamentHeaderCard({
    super.key,
    required this.tournament,
    required this.deck,
    required this.onEditFinalStanding,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = tournament.status == 'finished';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (deck != null) ...[
                        SpriteAvatarGroup(
                          sprite1: deck!.sprite1,
                          sprite2: deck!.sprite2,
                          size: AppSizes.iconNormal,
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                      ],
                      Expanded(
                        child: Text(
                          [
                            _formatDate(tournament.date),
                            if (deck != null) deck!.name,
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(isFinished ? 'Finalizado' : 'En curso'),
                  backgroundColor: (isFinished ? AppColors.muted : AppColors.success)
                      .withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isFinished ? AppColors.muted : AppColors.success,
                    fontSize: AppSizes.textXS,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              kTournamentStructureLabels[tournament.structure] ?? tournament.structure ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
            ),
            if (tournament.location != null && tournament.location!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingXS),
              Text(tournament.location!, style: const TextStyle(color: AppColors.muted)),
            ],
            if (tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingS),
              Text(
                '🏆 ${tournament.finalStanding}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if ((kStructurePhases[tournament.structure] ?? [])
                .any((p) => kRoundBasedPhases.contains(p))) ...[
              const SizedBox(height: AppSizes.spacingS),
              InkWell(
                onTap: onEditFinalStanding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_outlined, size: AppSizes.iconSmall, color: AppColors.muted),
                    const SizedBox(width: AppSizes.spacingXS),
                    Text(
                      tournament.finalStanding == null || tournament.finalStanding!.isEmpty
                          ? 'Añadir posición final'
                          : 'Editar posición final',
                      style: const TextStyle(color: AppColors.muted, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ],
            if (tournament.notes != null && tournament.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingS),
              Text(tournament.notes!, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
