import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament_player.dart';
import '../../../services/archetype_sprite_lookup.dart';
import '../../../widgets/sprite_avatar_group.dart';

/// Tarjeta de un jugador en la lista de gestion de un torneo hosted (issue
/// #118: extraida de tournament_players_screen.dart).
class PlayerListTile extends StatelessWidget {
  final TournamentPlayer player;
  final ArchetypeSpriteLookup spriteLookup;
  final VoidCallback onTap;

  const PlayerListTile({
    super.key,
    required this.player,
    required this.spriteLookup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sprites = spriteLookup.spritesForName(player.deckArchetype);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: SpriteAvatarGroup(
          sprite1: sprites.$1,
          sprite2: sprites.$2,
          size: AppSizes.iconNormal,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                player.name,
                style: TextStyle(
                  decoration: player.dropped ? TextDecoration.lineThrough : null,
                  color: player.dropped ? AppColors.muted : null,
                ),
              ),
            ),
            if (player.isOrganizer) ...[
              const SizedBox(width: AppSizes.spacingXS),
              const Icon(Icons.star, size: AppSizes.iconSmall, color: AppColors.primary),
            ],
          ],
        ),
        subtitle: Text(
          [
            if (player.deckArchetype != null) player.deckArchetype!,
            '${player.wins}V-${player.losses}D-${player.draws}E · ${player.points} pts',
            if (player.dropped) 'Baja',
          ].join(' · '),
        ),
      ),
    );
  }
}
