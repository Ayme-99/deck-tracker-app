import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import 'bracket_connector_painter.dart';
import 'bracket_constants.dart';
import 'bracket_layout.dart';
import 'bracket_node_card.dart';

/// Arbol de eliminatoria directa (issue #46), combinando el estilo de
/// bracketmaker.app (columnas por fase, conectores en angulo recto) y de
/// la app "Winner" (tema oscuro, sprite por jugador, "Sin resultado" en
/// vez de badge "vs"). Ver capturas de referencia en la conversacion.
///
/// FIX (issue #80): agrupa first_leg+second_leg[+sudden_death] en un
/// unico nodo visual via tiedMatchId, en vez de pintar cada partida
/// suelta como un nodo independiente.
///
/// FIX (issue #84): pantalla independiente con pan/zoom (interactive:true).
///
/// FIX (bug post-#84): la formula de centrado asumia que cada fase tiene
/// siempre la mitad de nodos que la anterior (bracket normal). Con una
/// ronda previa reducida (extra>0 en calculateEliminationEntry), la
/// relacion puede ser 1:1 (cada bye se empareja con 1 ganador de la
/// previa) en vez de 2:1 -- se detecta el caso irregular y se usa
/// reparto uniforme + conectores rectos 1 a 1 en su lugar, evitando que
/// varias tarjetas colapsen en la misma posicion.
///
/// REFACTOR (issue #115): la logica de agrupacion/reordenamiento/centrado
/// vive ahora en `bracket_layout.dart` (Dart puro, testeado sin
/// WidgetTester); este archivo solo se encarga del render.
class TournamentBracket extends StatefulWidget {
  final List<String> phaseOrder;
  final Map<String, List<TournamentMatch>> matchesByPhase;
  final Map<String, TournamentPlayer> playersById;
  final void Function(TournamentMatch match) onMatchTap;
  // Si true, el bracket se envuelve en InteractiveViewer (pan + zoom libre,
  // "tipo mapa", issue #84) en vez del SingleChildScrollView horizontal
  // habitual usado cuando se muestra embebido dentro de otra lista.
  final bool interactive;

  static const double dividerHeight = BracketConstants.dividerHeight;
  static const double rowHeight = BracketConstants.rowHeight;
  static const double cardHeight = BracketConstants.cardHeight;
  static const double cardWidth = BracketConstants.cardWidth;
  static const double leafGap = BracketConstants.leafGap;
  static const double colGap = BracketConstants.colGap;

  const TournamentBracket({
    super.key,
    required this.phaseOrder,
    required this.matchesByPhase,
    required this.playersById,
    required this.onMatchTap,
    this.interactive = false,
  });

  @override
  State<TournamentBracket> createState() => _TournamentBracketState();
}

class _TournamentBracketState extends State<TournamentBracket> {
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _recenter() {
    _transformationController.value = Matrix4.identity();
  }

  TournamentPlayer? _player(String? id) => id == null ? null : widget.playersById[id];

  @override
  Widget build(BuildContext context) {
    const cardHeight = BracketConstants.cardHeight;
    const cardWidth = BracketConstants.cardWidth;
    const leafGap = BracketConstants.leafGap;
    const colGap = BracketConstants.colGap;
    const labelHeight = BracketConstants.labelHeight;

    final matchesByPhase = widget.matchesByPhase;

    final layout = BracketLayout.compute(
      phaseOrder: widget.phaseOrder,
      matchesByPhase: matchesByPhase,
      cardHeight: cardHeight,
      leafGap: leafGap,
      labelHeight: labelHeight,
    );

    if (layout.phasesWithMatches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.spacingL),
        child: Center(child: Text('Todavía no hay bracket generado', style: TextStyle(color: AppColors.muted))),
      );
    }

    final phasesWithMatches = layout.phasesWithMatches;
    final nodesByPhase = layout.nodesByPhase;
    final centers = layout.centersByPhase;

    TournamentMatch? thirdPlaceMatch;
    for (final m in matchesByPhase['final'] ?? []) {
      if (m.isThirdPlaceMatch) {
        thirdPlaceMatch = m;
        break;
      }
    }

    final totalHeight = centers[phasesWithMatches.first]!.isEmpty
        ? cardHeight + labelHeight
        : centers[phasesWithMatches.first]!.last + cardHeight / 2 + leafGap;
    final totalWidth = phasesWithMatches.length * cardWidth + (phasesWithMatches.length - 1) * colGap;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: BracketConnectorPainter(
                  phasesWithMatches: phasesWithMatches,
                  centers: centers,
                  connectorSourceIndices: layout.connectorSourceIndices,
                  cardWidth: cardWidth,
                  colGap: colGap,
                ),
              ),
              for (int i = 0; i < phasesWithMatches.length; i++)
                for (int j = 0; j < nodesByPhase[phasesWithMatches[i]]!.length; j++)
                  Positioned(
                    left: i * (cardWidth + colGap),
                    top: centers[phasesWithMatches[i]]![j] - cardHeight / 2,
                    child: BracketNodeCard(
                      width: cardWidth,
                      height: cardHeight,
                      node: nodesByPhase[phasesWithMatches[i]]![j],
                      player1: _player(nodesByPhase[phasesWithMatches[i]]![j].player1Id),
                      player2: _player(nodesByPhase[phasesWithMatches[i]]![j].player2Id),
                      onSelectMatch: widget.onMatchTap,
                    ),
                  ),
              for (int i = 0; i < phasesWithMatches.length; i++)
                Positioned(
                  left: i * (cardWidth + colGap),
                  top: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      kTournamentMatchPhaseLabels[phasesWithMatches[i]] ?? phasesWithMatches[i],
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: AppSizes.textXS),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (thirdPlaceMatch != null) ...[
          const SizedBox(height: AppSizes.spacingL),
          const Text('3er y 4º puesto', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: AppSizes.textXS)),
          const SizedBox(height: AppSizes.spacingXS),
          BracketNodeCard(
            width: cardWidth,
            height: cardHeight,
            node: BracketNode([thirdPlaceMatch]),
            player1: _player(thirdPlaceMatch.player1Id),
            player2: _player(thirdPlaceMatch.player2Id),
            onSelectMatch: widget.onMatchTap,
          ),
        ],
      ],
    );

    if (widget.interactive) {
      return Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.symmetric(horizontal: 300, vertical: 300),
              minScale: 0.3,
              maxScale: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingXL),
                // FIX: Positioned.fill fuerza al InteractiveViewer a una
                // altura limitada (la del viewport visible), y esa
                // restriccion se propagaba hasta el Column interno,
                // provocando overflow cuando el contenido (con las
                // tarjetas BYE añadidas) crecia mas alto que el viewport.
                // OverflowBox ignora esa restriccion del padre y deja que
                // el contenido tome su tamaño real -- el propio
                // InteractiveViewer se encarga de recortar/paneear segun
                // haga falta, sin que Flutter se queje de overflow.
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: content,
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSizes.spacingM,
            bottom: AppSizes.spacingM,
            child: FloatingActionButton.small(
              heroTag: 'bracket_recenter',
              tooltip: 'Centrar vista',
              onPressed: _recenter,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: content,
    );
  }
}
