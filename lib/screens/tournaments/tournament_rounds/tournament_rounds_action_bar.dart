import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament.dart';
import '../../../models/tournament_match.dart';
import '../../../models/tournament_player.dart';

/// Botonera de acciones disponibles segun el estado del torneo hosted
/// (issue #115: extraida de tournament_rounds_screen.dart) -- que boton
/// mostrar depende de la structure y de que fases/rondas ya existan.
class TournamentRoundsActionBar extends StatelessWidget {
  final Tournament? tournament;
  final List<TournamentMatch> matches;
  final List<TournamentPlayer> players;
  final bool hasEliminationMatches;
  final String? currentEliminationPhase;
  final VoidCallback onGenerateSwissRound;
  final VoidCallback onGenerateLeague;
  final VoidCallback onGenerateBracket;
  final VoidCallback onAssignGroups;
  final VoidCallback onGenerateGroupStage;
  final VoidCallback onClosePhase;
  final VoidCallback onAdvanceBracket;

  const TournamentRoundsActionBar({
    super.key,
    required this.tournament,
    required this.matches,
    required this.players,
    required this.hasEliminationMatches,
    required this.currentEliminationPhase,
    required this.onGenerateSwissRound,
    required this.onGenerateLeague,
    required this.onGenerateBracket,
    required this.onAssignGroups,
    required this.onGenerateGroupStage,
    required this.onClosePhase,
    required this.onAdvanceBracket,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament == null) return const SizedBox.shrink();
    final structure = tournament!.structure;
    final buttons = <Widget>[];

    if (structure == 'swiss') {
      buttons.add(FilledButton.icon(
        onPressed: onGenerateSwissRound,
        icon: const Icon(Icons.add),
        label: const Text('Generar ronda swiss'),
      ));
    } else if (structure == 'league') {
      final hasLeagueMatches = matches.any((m) => m.phase == 'league_round');
      if (!hasLeagueMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateLeague,
          icon: const Icon(Icons.calendar_month),
          label: const Text('Generar calendario de liga'),
        ));
      }
    } else if (structure == 'elimination') {
      if (!hasEliminationMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateBracket,
          icon: const Icon(Icons.account_tree),
          label: const Text('Generar bracket'),
        ));
      }
    } else if (structure == 'swiss_elimination') {
      if (!hasEliminationMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateSwissRound,
          icon: const Icon(Icons.add),
          label: const Text('Generar ronda swiss'),
        ));
        buttons.add(OutlinedButton.icon(
          onPressed: onClosePhase,
          icon: const Icon(Icons.flag),
          label: const Text('Cerrar fase suiza'),
        ));
      }
    } else if (structure == 'groups_elimination') {
      final hasGroups = players.any((p) => p.groupName != null);
      final hasGroupMatches = matches.any((m) => m.phase == 'group_stage');
      if (!hasGroups) {
        buttons.add(FilledButton.icon(
          onPressed: onAssignGroups,
          icon: const Icon(Icons.groups),
          label: const Text('Asignar grupos'),
        ));
      } else if (!hasGroupMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateGroupStage,
          icon: const Icon(Icons.calendar_month),
          label: const Text('Generar calendario de grupos'),
        ));
      } else if (!hasEliminationMatches) {
        buttons.add(OutlinedButton.icon(
          onPressed: onClosePhase,
          icon: const Icon(Icons.flag),
          label: const Text('Cerrar fase de grupos'),
        ));
      }
    }

    // Avanzar el bracket: disponible en cualquier estructura con fase
    // eliminatoria ya iniciada, mientras no se haya llegado a la final
    if (hasEliminationMatches && currentEliminationPhase != null && currentEliminationPhase != 'final') {
      buttons.add(FilledButton.icon(
        onPressed: onAdvanceBracket,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Avanzar a la siguiente fase'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: Wrap(spacing: AppSizes.spacingS, runSpacing: AppSizes.spacingS, children: buttons),
    );
  }
}
