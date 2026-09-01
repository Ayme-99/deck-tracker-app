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
              Icon(Icons.star, size: AppSizes.iconSmall, color: AppColors.primary),
            ],
            // Issue #242: distingue visualmente las inscripciones vinculadas
            // a la cuenta de un amigo (via invitacion aceptada) de las que
            // no tienen cuenta, mostrando su rol.
            if (player.linkedUserId != null) ...[
              const SizedBox(width: AppSizes.spacingXS),
              Chip(
                label: Text(player.role == 'admin' ? 'Admin' : 'Invitado'),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: const TextStyle(fontSize: AppSizes.textXS),
              ),
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
