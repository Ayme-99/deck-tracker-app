import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../models/tournament_match.dart';
import '../models/tournament_player.dart';
import 'sprite_avatar_group.dart';

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
class TournamentBracket extends StatefulWidget {
  final List<String> phaseOrder;
  final Map<String, List<TournamentMatch>> matchesByPhase;
  final Map<String, TournamentPlayer> playersById;
  final void Function(TournamentMatch match) onMatchTap;
  // Si true, el bracket se envuelve en InteractiveViewer (pan + zoom libre,
  // "tipo mapa", issue #84) en vez del SingleChildScrollView horizontal
  // habitual usado cuando se muestra embebido dentro de otra lista.
  final bool interactive;

  // FIX (issue #83): rowHeight es fijo, y cardHeight se calcula sumando
  // ambas filas + el divisor + margen, en vez de derivar rowHeight
  // dividiendo cardHeight entre 2 (eso no dejaba hueco para el Divider).
  static const double dividerHeight = 1;
  static const double rowHeight = 32;
  static const double cardHeight = rowHeight * 2 + dividerHeight + 4;
  static const double cardWidth = 210;
  static const double leafGap = 14;
  static const double colGap = 48;

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

  List<_BracketNode> _groupIntoNodes(List<TournamentMatch> phaseMatches) {
    final nodes = <_BracketNode>[];
    final seen = <String>{};

    for (final m in phaseMatches) {
      if (seen.contains(m.id)) continue;
      final group = [m];
      seen.add(m.id);

      if (m.tiedMatchId != null) {
        for (final other in phaseMatches) {
          if (seen.contains(other.id)) continue;
          final isLinked = other.id == m.tiedMatchId || other.tiedMatchId == m.id;
          if (isLinked) {
            group.add(other);
            seen.add(other.id);
          }
        }
      }

      nodes.add(_BracketNode(group));
    }

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final phaseOrder = widget.phaseOrder;
    final matchesByPhase = widget.matchesByPhase;
    final onMatchTap = widget.onMatchTap;
    const cardHeight = TournamentBracket.cardHeight;
    const cardWidth = TournamentBracket.cardWidth;
    const leafGap = TournamentBracket.leafGap;
    const colGap = TournamentBracket.colGap;

    final phasesWithMatches = phaseOrder.where((p) => (matchesByPhase[p] ?? []).isNotEmpty).toList();
    if (phasesWithMatches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.spacingL),
        child: Center(child: Text('Todavía no hay bracket generado', style: TextStyle(color: AppColors.muted))),
      );
    }

    TournamentMatch? thirdPlaceMatch;
    for (final m in matchesByPhase['final'] ?? []) {
      if (m.isThirdPlaceMatch) {
        thirdPlaceMatch = m;
        break;
      }
    }

    final nodesByPhase = {
      for (final p in phasesWithMatches)
        p: _groupIntoNodes((matchesByPhase[p] ?? []).where((m) => !m.isThirdPlaceMatch).toList()),
    };

    final centers = <String, List<double>>{};
    for (int i = 0; i < phasesWithMatches.length; i++) {
      final phase = phasesWithMatches[i];
      final nodes = nodesByPhase[phase]!;
      if (i == 0) {
        centers[phase] = List.generate(
          nodes.length,
          (idx) => idx * (cardHeight + leafGap) + cardHeight / 2,
        );
      } else {
        final prevPhase = phasesWithMatches[i - 1];
        final prevCenters = centers[prevPhase]!;
        final isStandardHalving = nodes.length == (prevCenters.length / 2).ceil();
        if (isStandardHalving) {
          centers[phase] = List.generate(nodes.length, (idx) {
            final c1 = prevCenters.length > idx * 2 ? prevCenters[idx * 2] : 0.0;
            final c2 = prevCenters.length > idx * 2 + 1 ? prevCenters[idx * 2 + 1] : c1;
            return (c1 + c2) / 2;
          });
        } else {
          centers[phase] = List.generate(
            nodes.length,
            (idx) => idx * (cardHeight + leafGap) + cardHeight / 2,
          );
        }
      }
    }

    const labelHeight = 24.0;
    for (final phase in centers.keys) {
      centers[phase] = centers[phase]!.map((c) => c + labelHeight).toList();
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
                painter: _BracketConnectorPainter(
                  phasesWithMatches: phasesWithMatches,
                  centers: centers,
                ),
              ),
              for (int i = 0; i < phasesWithMatches.length; i++)
                for (int j = 0; j < nodesByPhase[phasesWithMatches[i]]!.length; j++)
                  Positioned(
                    left: i * (cardWidth + colGap),
                    top: centers[phasesWithMatches[i]]![j] - cardHeight / 2,
                    child: _BracketNodeCard(
                      width: cardWidth,
                      height: cardHeight,
                      node: nodesByPhase[phasesWithMatches[i]]![j],
                      player1: _player(nodesByPhase[phasesWithMatches[i]]![j].player1Id),
                      player2: _player(nodesByPhase[phasesWithMatches[i]]![j].player2Id),
                      onSelectMatch: onMatchTap,
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
          _BracketNodeCard(
            width: cardWidth,
            height: cardHeight,
            node: _BracketNode([thirdPlaceMatch]),
            player1: _player(thirdPlaceMatch.player1Id),
            player2: _player(thirdPlaceMatch.player2Id),
            onSelectMatch: onMatchTap,
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
                child: content,
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

class _BracketNode {
  final List<TournamentMatch> legs;

  _BracketNode(this.legs);

  bool get isTwoLegs => legs.length > 1;

  String get player1Id => legs.first.player1Id;
  String? get player2Id => legs.first.player2Id;
  bool get isBye => legs.first.isBye;

  TournamentMatch? get _firstLeg =>
      legs.length == 1 ? null : (legs.where((m) => m.leg == 'first_leg').firstOrNull ?? legs.first);
  TournamentMatch? get _secondLeg =>
      legs.length == 1 ? null : legs.where((m) => m.leg == 'second_leg').firstOrNull;
  TournamentMatch? get _suddenDeath =>
      legs.length == 1 ? null : legs.where((m) => m.leg == 'sudden_death').firstOrNull;

  String get resultLabel {
    if (legs.length == 1) {
      final m = legs.first;
      if (m.status != 'completed') return 'Sin resultado';
      if (m.isDraw) return 'Empate';
      return '${m.player1Prizes ?? '-'} - ${m.player2Prizes ?? '-'}';
    }

    final firstLeg = _firstLeg;
    final secondLeg = _secondLeg;
    final suddenDeath = _suddenDeath;

    if (suddenDeath != null && suddenDeath.status == 'completed') {
      return 'Agregado + muerte súbita';
    }
    if (firstLeg != null && firstLeg.status == 'completed' && secondLeg != null && secondLeg.status == 'completed') {
      final p1Total = (firstLeg.player1Prizes ?? 0) +
          (secondLeg.player2Id == firstLeg.player1Id ? (secondLeg.player2Prizes ?? 0) : (secondLeg.player1Prizes ?? 0));
      final p2Total = (firstLeg.player2Prizes ?? 0) +
          (secondLeg.player1Id == firstLeg.player2Id ? (secondLeg.player1Prizes ?? 0) : (secondLeg.player2Prizes ?? 0));
      if (p1Total == p2Total) return 'Empate agregado ($p1Total-$p2Total) · falta muerte súbita';
      return '$p1Total - $p2Total (agregado)';
    }
    if (firstLeg != null && firstLeg.status == 'completed') {
      return 'Ida: ${firstLeg.player1Prizes ?? '-'}-${firstLeg.player2Prizes ?? '-'} · Vuelta pendiente';
    }
    return 'Sin resultado';
  }

  bool get hasAnyResult => legs.any((m) => m.status == 'completed');
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _BracketNodeCard extends StatelessWidget {
  final double width;
  final double height;
  final _BracketNode node;
  final TournamentPlayer? player1;
  final TournamentPlayer? player2;
  final void Function(TournamentMatch match) onSelectMatch;

  const _BracketNodeCard({
    required this.width,
    required this.height,
    required this.node,
    required this.player1,
    required this.player2,
    required this.onSelectMatch,
  });

  Widget _row(TournamentPlayer? player, {required bool isBye}) {
    return SizedBox(
      height: TournamentBracket.rowHeight,
      child: Row(
        children: [
          const SpriteAvatarGroup(
            sprite1: null,
            size: AppSizes.iconSmall,
            centerAlign: true,
          ),
          const SizedBox(width: AppSizes.spacingXS),
          Expanded(
            child: Text(
              isBye ? 'BYE' : (player?.name ?? '?'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isBye ? AppColors.muted : null),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (!node.isTwoLegs) {
      onSelectMatch(node.legs.first);
      return;
    }

    final selected = await showModalBottomSheet<TournamentMatch>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: node.legs.map((leg) {
            final label = switch (leg.leg) {
              'first_leg' => 'Ida',
              'second_leg' => 'Vuelta',
              'sudden_death' => 'Muerte súbita',
              _ => leg.leg,
            };
            final resultText = leg.status == 'completed'
                ? (leg.isDraw ? 'Empate' : '${leg.player1Prizes ?? '-'}-${leg.player2Prizes ?? '-'}')
                : 'Sin resultado';
            return ListTile(
              title: Text(label),
              subtitle: Text(resultText),
              onTap: () => Navigator.of(context).pop(leg),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) onSelectMatch(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingS),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _row(player1, isBye: false),
                  const Divider(height: TournamentBracket.dividerHeight),
                  _row(player2, isBye: node.isBye),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spacingXS),
            Text(
              node.resultLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: node.hasAnyResult ? null : AppColors.muted,
                fontSize: AppSizes.textXS,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketConnectorPainter extends CustomPainter {
  final List<String> phasesWithMatches;
  final Map<String, List<double>> centers;

  _BracketConnectorPainter({
    required this.phasesWithMatches,
    required this.centers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < phasesWithMatches.length - 1; i++) {
      final phase = phasesWithMatches[i];
      final nextPhaseName = phasesWithMatches[i + 1];
      final phaseCenters = centers[phase]!;
      final nextCenters = centers[nextPhaseName]!;

      final x1 = i * (TournamentBracket.cardWidth + TournamentBracket.colGap) + TournamentBracket.cardWidth;
      final xMid = x1 + TournamentBracket.colGap / 2;
      final x2 = (i + 1) * (TournamentBracket.cardWidth + TournamentBracket.colGap);

      final isStandardHalving = nextCenters.length == (phaseCenters.length / 2).ceil();

      if (isStandardHalving) {
        for (int j = 0; j < nextCenters.length; j++) {
          final yChild0 = phaseCenters.length > j * 2 ? phaseCenters[j * 2] : null;
          final yChild1 = phaseCenters.length > j * 2 + 1 ? phaseCenters[j * 2 + 1] : null;
          final yParent = nextCenters[j];

          if (yChild0 != null) canvas.drawLine(Offset(x1, yChild0), Offset(xMid, yChild0), paint);
          if (yChild1 != null) canvas.drawLine(Offset(x1, yChild1), Offset(xMid, yChild1), paint);
          if (yChild0 != null && yChild1 != null) {
            canvas.drawLine(Offset(xMid, yChild0), Offset(xMid, yChild1), paint);
          }
          canvas.drawLine(Offset(xMid, yParent), Offset(x2, yParent), paint);
        }
      } else {
        for (int j = 0; j < phaseCenters.length && j < nextCenters.length; j++) {
          canvas.drawLine(Offset(x1, phaseCenters[j]), Offset(x2, nextCenters[j]), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) => true;
}