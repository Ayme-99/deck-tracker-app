import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/match.dart';
import '../../../models/opponent_archetype.dart';
import '../../../widgets/sprite_avatar_group.dart';

/// Ultimas partidas registradas con este mazo (issue #118: promocionada
/// desde _buildRecentMatchesSection de deck_detail_screen.dart a un widget
/// de verdad).
class DeckRecentMatchesSection extends StatelessWidget {
  final List<Match> matches;
  final Map<String, OpponentArchetype> archetypesByName;
  final void Function(Match match) onMatchTap;

  const DeckRecentMatchesSection({
    super.key,
    required this.matches,
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

  String _resultLabel(String result) {
    switch (result) {
      case 'win':
        return 'Victoria';
      case 'loss':
        return 'Derrota';
      default:
        return 'Empate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Partidas recientes', style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.spacingSM),
        if (matches.isEmpty)
          const Text('Todavía no hay partidas registradas', style: TextStyle(color: Colors.grey))
        else
          ...matches.map((match) {
            final archetype = archetypesByName[match.opponentDeck];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => onMatchTap(match),
                minLeadingWidth: 0,
                horizontalTitleGap: AppSizes.spacingS,
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
                  '${_resultLabel(match.result)} · ${match.userPrizes}-${match.opponentPrizes}',
                ),
                trailing: Text(
                  '${match.playedAt.day}/${match.playedAt.month}',
                  style: TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                ),
              ),
            );
          }),
      ],
    );
  }
}
