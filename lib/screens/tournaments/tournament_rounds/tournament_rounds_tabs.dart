import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament_match.dart' show TournamentMatch, kEliminationPhaseOrder;
import '../../../models/tournament_player.dart';
import '../../../widgets/tournament_bracket/tournament_bracket.dart';
import 'tournament_match_card.dart';

/// Descriptor de una pestaña combinada (issue #85): representa o bien una
/// ronda concreta de una fase con rondas (swiss/liga/grupos), o bien una
/// fase de eliminatoria completa (Octavos, Cuartos...). Las de ronda
/// muestran un listado simple; las de fase desplazan el arbol del bracket
/// (ya montado de forma persistente) hasta esa columna.
///
/// (issue #115: publica -- antes era `_TabEntry`, privada del archivo
/// monolitico de la pantalla -- para poder usarla desde el widget de tabs
/// ya extraido.)
class TournamentRoundsTabEntry {
  final String label;
  final bool isPhase;
  final String phase;
  final int? round;

  TournamentRoundsTabEntry.round({required this.label, required this.phase, required this.round}) : isPhase = false;
  TournamentRoundsTabEntry.phase({required this.label, required this.phase})
      : isPhase = true,
        round = null;
}

/// Pestañas combinadas de rondas/fases + bracket embebido de un torneo
/// hosted (issue #115: extraida de tournament_rounds_screen.dart). El
/// `TabController` se gestiona en la pantalla (necesita `vsync` del
/// `State`), este widget solo renderiza segun su estado actual.
class TournamentRoundsTabs extends StatelessWidget {
  final TabController tabController;
  final List<TournamentRoundsTabEntry> tabEntries;
  final Map<String, List<TournamentMatch>> matchesByPhase;
  final Map<String, TournamentPlayer> playersById;
  final (String?, String?) Function(String? name) spritesForName;
  final void Function(TournamentMatch match) onMatchTap;

  const TournamentRoundsTabs({
    super.key,
    required this.tabController,
    required this.tabEntries,
    required this.matchesByPhase,
    required this.playersById,
    required this.spritesForName,
    required this.onMatchTap,
  });

  TournamentPlayer? _player(String? id) => id == null ? null : playersById[id];

  @override
  Widget build(BuildContext context) {
    if (tabEntries.isEmpty) return const SizedBox.shrink();

    final anyPhaseTab = tabEntries.any((e) => e.isPhase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final e in tabEntries) Tab(text: e.label)],
        ),
        Expanded(
          child: Stack(
            children: [
              for (int i = 0; i < tabEntries.length; i++)
                if (!tabEntries[i].isPhase)
                  Offstage(
                    offstage: tabController.index != i,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM, vertical: AppSizes.spacingS),
                      children: matchesByPhase[tabEntries[i].phase]!
                          .where((m) => (m.round ?? 0) == tabEntries[i].round)
                          .map((match) {
                        final p1 = _player(match.player1Id);
                        final p2 = match.player2Id != null ? _player(match.player2Id) : null;
                        return TournamentMatchCard(
                          match: match,
                          player1: p1,
                          player2: p2,
                          player1Sprites: spritesForName(p1?.deckArchetype),
                          player2Sprites: spritesForName(p2?.deckArchetype),
                          onTap: () => onMatchTap(match),
                        );
                      }).toList(),
                    ),
                  ),
              // El bracket se mantiene siempre montado (Offstage, no
              // eliminado del arbol) para no perder su posicion de scroll
              // al cambiar entre pestañas de fase.
              if (anyPhaseTab)
                Offstage(
                  offstage: !tabEntries[tabController.index].isPhase,
                  // FIX: el arbol del bracket solo se desplazaba en horizontal por
                  // dentro (via scrollController) -- dentro de la caja de altura fija
                  // de las pestañas, con muchas tarjetas en la primera fase (16, y
                  // hasta 32 cuando soportemos 64 jugadores) siempre desbordaba
                  // verticalmente. Se envuelve en un SingleChildScrollView vertical
                  // para que tambien se pueda desplazar hacia abajo dentro de la caja.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: TournamentBracket(
                      phaseOrder: kEliminationPhaseOrder,
                      matchesByPhase: matchesByPhase,
                      playersById: playersById,
                      onMatchTap: onMatchTap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
