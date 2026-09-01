import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament.dart';
import '../../../models/tournament_match.dart';
import '../../../models/tournament_player.dart';
import '../../../l10n/app_localizations.dart';

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
  final VoidCallback onFinishTournament;

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
    required this.onFinishTournament,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final structure = tournament!.structure;
    final buttons = <Widget>[];

    if (structure == 'swiss') {
      buttons.add(FilledButton.icon(
        onPressed: onGenerateSwissRound,
        icon: const Icon(Icons.add),
        label: Text(l10n.generateSwissRoundAction),
      ));
    } else if (structure == 'league') {
      final hasLeagueMatches = matches.any((m) => m.phase == 'league_round');
      if (!hasLeagueMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateLeague,
          icon: const Icon(Icons.calendar_month),
          label: Text(l10n.generateLeagueScheduleAction),
        ));
      }
    } else if (structure == 'elimination') {
      if (!hasEliminationMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateBracket,
          icon: const Icon(Icons.account_tree),
          label: Text(l10n.generateBracketAction),
        ));
      }
    } else if (structure == 'swiss_elimination') {
      if (!hasEliminationMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateSwissRound,
          icon: const Icon(Icons.add),
          label: Text(l10n.generateSwissRoundAction),
        ));
        buttons.add(OutlinedButton.icon(
          onPressed: onClosePhase,
          icon: const Icon(Icons.flag),
          label: Text(l10n.closeSwissPhaseAction),
        ));
      }
    } else if (structure == 'groups_elimination') {
      final hasGroups = players.any((p) => p.groupName != null);
      final hasGroupMatches = matches.any((m) => m.phase == 'group_stage');
      if (!hasGroups) {
        buttons.add(FilledButton.icon(
          onPressed: onAssignGroups,
          icon: const Icon(Icons.groups),
          label: Text(l10n.assignGroupsAction),
        ));
      } else if (!hasGroupMatches) {
        buttons.add(FilledButton.icon(
          onPressed: onGenerateGroupStage,
          icon: const Icon(Icons.calendar_month),
          label: Text(l10n.generateGroupScheduleAction),
        ));
      } else if (!hasEliminationMatches) {
        buttons.add(OutlinedButton.icon(
          onPressed: onClosePhase,
          icon: const Icon(Icons.flag),
          label: Text(l10n.closeGroupPhaseAction),
        ));
      }
    }

    // Avanzar el bracket: disponible en cualquier estructura con fase
    // eliminatoria ya iniciada, mientras no se haya llegado a la final
    if (hasEliminationMatches && currentEliminationPhase != null && currentEliminationPhase != 'final') {
      buttons.add(FilledButton.icon(
        onPressed: onAdvanceBracket,
        icon: const Icon(Icons.arrow_forward),
        label: Text(l10n.advanceToNextPhaseAction),
      ));
    }

    // Issue #207: antes "Finalizar torneo" solo vivia en el menu de la
    // lista de Torneos (otra pantalla) -- una vez se llega a la final, se
    // ofrece tambien aqui mismo, donde se esta jugando.
    if (hasEliminationMatches && currentEliminationPhase == 'final' && tournament!.status != 'finished') {
      buttons.add(FilledButton.icon(
        onPressed: onFinishTournament,
        icon: const Icon(Icons.emoji_events),
        label: Text(l10n.finishTournamentAction),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: Wrap(spacing: AppSizes.spacingS, runSpacing: AppSizes.spacingS, children: buttons),
    );
  }
}
