import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/opponent_archetype.dart';
import '../../../widgets/sprite_avatar_group.dart';

/// Win-rate contra cada arquetipo rival al que se ha enfrentado este mazo
/// (issue #118: promocionada desde _buildMatchupsSection de
/// deck_detail_screen.dart a un widget de verdad).
class DeckMatchupsSection extends StatelessWidget {
  final List<dynamic> matchups;
  final Map<String, OpponentArchetype> archetypesByName;

  const DeckMatchupsSection({super.key, required this.matchups, required this.archetypesByName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Matchups', style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.spacingM),
        if (matchups.isEmpty)
          const Text('Todavía no hay partidas registradas', style: TextStyle(color: AppColors.muted))
        else
          ...matchups.map((m) {
            final archetype = archetypesByName[m['opponentDeck']];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                minLeadingWidth: 0,
                horizontalTitleGap: AppSizes.spacingS,
                leading: SpriteAvatarGroup(
                  sprite1: archetype?.sprite1,
                  sprite2: archetype?.sprite2,
                  size: AppSizes.iconNormal,
                ),
                title: Text(m['opponentDeck']),
                subtitle: Text('${m['wins']}V - ${m['losses']}D - ${m['ties']}E'),
                trailing: Text(
                  '${m['winRate']}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }
}
