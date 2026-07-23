import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/match.dart';
import '../../../models/opponent_archetype.dart';
import '../../../widgets/sprite_avatar_group.dart';

/// Partidas de un torneo tracked, agrupadas por fase (issue #115: extraida
/// de tournament_detail_screen.dart).
class TournamentMatchesList extends StatelessWidget {
  final Map<String, List<Match>> groupedMatches;
  final Map<String, OpponentArchetype> archetypesByName;
  final void Function(Match match) onMatchTap;

  const TournamentMatchesList({
    super.key,
    required this.groupedMatches,
    required this.archetypesByName,
    required this.onMatchTap,
  });

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return AppColors.success;
      case 'loss':
        return AppColors.error;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (groupedMatches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.spacingM),
        child: Text(
          'Todavía no hay partidas registradas en este torneo',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedMatches.entries.map((entry) {
        final phase = entry.key;
        final matches = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kMatchPhaseLabels[phase] ?? phase,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.spacingXS),
              ...matches.map((match) {
                final archetype = archetypesByName[match.opponentDeck];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingXS),
                  child: ListTile(
                    leading: archetype?.sprite1 != null
                        ? SpriteAvatarGroup(
                            sprite1: archetype!.sprite1,
                            sprite2: archetype.sprite2,
                            size: AppSizes.iconNormal,
                          )
                        : CircleAvatar(
                            backgroundColor: _resultColor(match.result).withValues(alpha: 0.15),
                            child: Icon(
                              match.result == 'win'
                                  ? Icons.check
                                  : match.result == 'loss'
                                      ? Icons.close
                                      : Icons.remove,
                              color: _resultColor(match.result),
                            ),
                          ),
                    title: Text('vs ${match.opponentDeck}'),
                    subtitle: Text(
                      [
                        if (match.round != null) 'Ronda ${match.round}',
                        '${match.userPrizes}-${match.opponentPrizes}',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                    onTap: () => onMatchTap(match),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
