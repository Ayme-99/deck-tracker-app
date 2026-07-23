import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament_match.dart';
import '../../../models/tournament_player.dart';
import '../../../widgets/sprite_avatar_group.dart';

/// Tarjeta de un emparejamiento en el listado simple (swiss/liga/grupos),
/// issue #115: extraida de tournament_rounds_screen.dart.
class TournamentMatchCard extends StatelessWidget {
  final TournamentMatch match;
  final TournamentPlayer? player1;
  final TournamentPlayer? player2;
  final (String?, String?) player1Sprites;
  final (String?, String?) player2Sprites;
  final VoidCallback onTap;

  const TournamentMatchCard({
    super.key,
    required this.match,
    required this.player1,
    required this.player2,
    required this.player1Sprites,
    required this.player2Sprites,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingXS),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: SpriteAvatarGroup(sprite1: player1Sprites.$1, sprite2: player1Sprites.$2, size: AppSizes.iconNormal),
          trailing: match.isBye
              ? null
              : SpriteAvatarGroup(sprite1: player2Sprites.$1, sprite2: player2Sprites.$2, size: AppSizes.iconNormal),
          title: Text('${player1?.name ?? '?'} vs ${match.isBye ? 'BYE' : (player2?.name ?? '?')}'),
          subtitle: Text(
            match.status == 'completed'
                ? (match.isDraw ? 'Empate' : '${match.player1Prizes ?? '-'}-${match.player2Prizes ?? '-'}')
                : 'Sin resultado',
          ),
        ),
      ),
    );
  }
}
