import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../sprite_avatar_group.dart';

/// Datos introducidos en el dialogo de resultado (issues #185/#195): el
/// llamador decide que hacer con ellos (guardar, mostrar error...), este
/// widget solo se encarga de recogerlos.
class MatchResultInput {
  final int? player1Prizes;
  final int? player2Prizes;
  final String? winnerId;
  final bool isDraw;

  MatchResultInput({
    required this.player1Prizes,
    required this.player2Prizes,
    required this.winnerId,
    required this.isDraw,
  });
}

/// Dialogo para registrar el resultado de una partida hosted (premios +
/// ganador/empate). Antes vivia duplicado casi al detalle en
/// tournament_rounds_screen.dart y tournament_bracket_screen.dart (issue
/// #195) -- se unifica aqui.
///
/// El ganador es una eleccion independiente de los premios, nunca se deduce
/// ni se valida contra ellos: una rendicion, un mazo agotado o el tiempo
/// pueden darle la partida a quien iba perdiendo en premios (issue #185).
/// El boton "Guardar" solo exige que se haya elegido explicitamente un
/// ganador o marcado empate -- nunca hay una opcion preseleccionada por
/// defecto.
///
/// Los sprites del titulo son opcionales: si el llamador no los tiene
/// cargados (como tournament_bracket_screen.dart hoy), se omiten sin más.
Future<MatchResultInput?> showMatchResultDialog(
  BuildContext context, {
  required TournamentMatch match,
  required TournamentPlayer? player1,
  required TournamentPlayer? player2,
  (String?, String?)? player1Sprites,
  (String?, String?)? player2Sprites,
}) async {
  final p1Controller = TextEditingController(text: match.player1Prizes?.toString() ?? '');
  final p2Controller = TextEditingController(text: match.player2Prizes?.toString() ?? '');
  bool isDraw = match.isDraw;
  String? winnerId = match.winnerId;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player1Sprites != null) ...[
              SpriteAvatarGroup(sprite1: player1Sprites.$1, sprite2: player1Sprites.$2, size: AppSizes.iconNormal),
              const SizedBox(width: AppSizes.spacingXS),
            ],
            Flexible(
              child: Text(
                '${player1?.name ?? '?'} vs ${player2?.name ?? '?'}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player2Sprites != null) ...[
              const SizedBox(width: AppSizes.spacingXS),
              SpriteAvatarGroup(sprite1: player2Sprites.$1, sprite2: player2Sprites.$2, size: AppSizes.iconNormal),
            ],
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: p1Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Premios de ${player1?.name ?? 'jugador 1'}'),
            ),
            const SizedBox(height: AppSizes.spacingS),
            TextField(
              controller: p2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Premios de ${player2?.name ?? 'jugador 2'}'),
            ),
            const SizedBox(height: AppSizes.spacingM),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Empate'),
              value: isDraw,
              onChanged: (value) => setDialogState(() => isDraw = value),
            ),
            if (!isDraw) ...[
              RadioGroup<String>(
                groupValue: winnerId,
                onChanged: (value) => setDialogState(() => winnerId = value),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Gana ${player1?.name ?? 'jugador 1'}'),
                      value: match.player1Id,
                    ),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Gana ${player2?.name ?? 'jugador 2'}'),
                      value: match.player2Id!,
                    ),
                  ],
                ),
              ),
              // Issue #185: el ganador NO se deduce de los premios --
              // aclarado explicitamente para no dar por hecho que ambos
              // campos deben "cuadrar" entre si.
              const Text(
                'El ganador puede no coincidir con los premios (rendición, mazo agotado, tiempo...)',
                style: TextStyle(fontSize: AppSizes.textXS, color: AppColors.muted),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: (!isDraw && winnerId == null) ? null : () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return null;

  return MatchResultInput(
    player1Prizes: int.tryParse(p1Controller.text),
    player2Prizes: int.tryParse(p2Controller.text),
    winnerId: isDraw ? null : winnerId,
    isDraw: isDraw,
  );
}
