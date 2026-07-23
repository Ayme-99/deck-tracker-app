import '../../models/tournament_match.dart';

/// Logica pura (sin Flutter) del arbol de eliminatoria directa. Extraida de
/// `TournamentBracket` (issue #115) para poder testearla sin `WidgetTester`
/// y para que el painter de conectores no repita el calculo de fuentes.
///
/// Agrupa partidas en nodos visuales (juntando ida/vuelta/muerte subita via
/// `tiedMatchId`), reordena cada fase anterior para que las 2 fuentes reales
/// de cada partido siguiente queden adyacentes (por `winnerId`, no por
/// posicion), y calcula los centros Y de cada fase.
class BracketNode {
  final List<TournamentMatch> legs;

  BracketNode(this.legs);

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

  /// Ganador real de este nodo (jugador que avanza), null si aun no hay
  /// ganador determinable. Se usa para calcular los conectores del bracket
  /// comparando IDs de jugador entre fases, en vez de adivinar por posicion
  /// visual (ver fix del conector enganoso).
  String? get winnerId {
    if (legs.length == 1) {
      final m = legs.first;
      return (m.status == 'completed' && !m.isDraw) ? m.winnerId : null;
    }

    final firstLeg = _firstLeg;
    final secondLeg = _secondLeg;
    final suddenDeath = _suddenDeath;

    if (suddenDeath != null && suddenDeath.status == 'completed' && suddenDeath.winnerId != null) {
      return suddenDeath.winnerId;
    }
    if (firstLeg != null && firstLeg.status == 'completed' && secondLeg != null && secondLeg.status == 'completed') {
      final p1Total = (firstLeg.player1Prizes ?? 0) +
          (secondLeg.player2Id == firstLeg.player1Id ? (secondLeg.player2Prizes ?? 0) : (secondLeg.player1Prizes ?? 0));
      final p2Total = (firstLeg.player2Prizes ?? 0) +
          (secondLeg.player1Id == firstLeg.player2Id ? (secondLeg.player1Prizes ?? 0) : (secondLeg.player2Prizes ?? 0));
      if (p1Total == p2Total) return null; // agregado empatado, sin ganador aun
      return p1Total > p2Total ? firstLeg.player1Id : firstLeg.player2Id;
    }
    return null;
  }
}

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class BracketLayout {
  /// Fases con al menos una partida, en el orden de [phaseOrder] original.
  final List<String> phasesWithMatches;

  /// Nodos de cada fase, ya reordenados para que las 2 fuentes de cada nodo
  /// de la fase siguiente queden en posiciones adyacentes (con tarjetas BYE
  /// sinteticas rellenando huecos donde no hay fuente real).
  final Map<String, List<BracketNode>> nodesByPhase;

  /// Centro Y (en pixeles) de cada nodo, por fase.
  final Map<String, List<double>> centersByPhase;

  /// Para cada fase (excepto la primera), y cada indice de nodo en esa fase,
  /// los indices -- ya en el orden final de [nodesByPhase] de la fase
  /// anterior -- que alimentan a ese nodo (0, 1 o 2 elementos). Calculado una
  /// sola vez aqui para que el painter de conectores no repita la busqueda
  /// por winnerId.
  final Map<String, List<List<int>>> connectorSourceIndices;

  const BracketLayout._({
    required this.phasesWithMatches,
    required this.nodesByPhase,
    required this.centersByPhase,
    required this.connectorSourceIndices,
  });

  static const empty = BracketLayout._(
    phasesWithMatches: [],
    nodesByPhase: {},
    centersByPhase: {},
    connectorSourceIndices: {},
  );

  static List<BracketNode> _groupIntoNodes(List<TournamentMatch> phaseMatches) {
    final nodes = <BracketNode>[];
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

      nodes.add(BracketNode(group));
    }

    return nodes;
  }

  static BracketNode _byeNodeFor(String prevPhase, String? playerId, String label) => BracketNode([
        TournamentMatch(
          id: 'virtual-bye-${playerId ?? "?"}-$label',
          phase: prevPhase,
          player1Id: playerId ?? '?',
          status: 'completed',
          isDraw: false,
          leg: 'single',
          winnerId: playerId,
        ),
      ]);

  /// Calcula el layout completo a partir de las partidas por fase.
  ///
  /// [cardHeight]/[leafGap] determinan el espaciado vertical de la primera
  /// fase (y de cualquier fase con reparto uniforme); [labelHeight] es el
  /// desplazamiento vertical fijo que deja hueco a la etiqueta de la fase.
  static BracketLayout compute({
    required List<String> phaseOrder,
    required Map<String, List<TournamentMatch>> matchesByPhase,
    required double cardHeight,
    required double leafGap,
    double labelHeight = 0,
  }) {
    final phasesWithMatches = phaseOrder.where((p) => (matchesByPhase[p] ?? []).isNotEmpty).toList();
    if (phasesWithMatches.isEmpty) return empty;

    final nodesByPhase = <String, List<BracketNode>>{
      for (final p in phasesWithMatches)
        p: _groupIntoNodes((matchesByPhase[p] ?? []).where((m) => !m.isThirdPlaceMatch).toList()),
    };

    // Reordena SIEMPRE cada fase anterior segun las fuentes reales (por
    // winnerId) de la fase siguiente, para que cualquier fusion en V sea
    // siempre entre dos filas contiguas (ver comentario historico en
    // tournament_bracket.dart antes de la extraccion, issue #80/#115).
    final connectorSourceIndices = <String, List<List<int>>>{};

    for (int i = 0; i < phasesWithMatches.length - 1; i++) {
      final prevPhase = phasesWithMatches[i];
      final nextPhase = phasesWithMatches[i + 1];
      final prevNodes = nodesByPhase[prevPhase]!;
      final nextNodes = nodesByPhase[nextPhase]!;

      final usedMatchIds = <String>{};
      final reordered = <BracketNode>[];
      final sourcesByNextIndex = <List<int>>[];

      for (final nextNode in nextNodes) {
        BracketNode? source1;
        BracketNode? source2;
        for (final pn in prevNodes) {
          final matchId = pn.legs.first.id;
          if (usedMatchIds.contains(matchId)) continue;
          final w = pn.winnerId;
          if (w == null) continue;
          if (w == nextNode.player1Id && source1 == null) {
            source1 = pn;
            usedMatchIds.add(matchId);
          } else if (w == nextNode.player2Id && source2 == null) {
            source2 = pn;
            usedMatchIds.add(matchId);
          }
        }

        final idx1 = reordered.length;
        reordered.add(source1 ?? _byeNodeFor(prevPhase, nextNode.player1Id, nextNode.legs.first.id));
        final idx2 = reordered.length;
        reordered.add(source2 ?? _byeNodeFor(prevPhase, nextNode.player2Id, nextNode.legs.first.id));

        final sources = <int>[];
        if (reordered[idx1].winnerId != null) sources.add(idx1);
        if (reordered[idx2].winnerId != null) sources.add(idx2);
        sourcesByNextIndex.add(sources);
      }

      nodesByPhase[prevPhase] = reordered;
      connectorSourceIndices[nextPhase] = sourcesByNextIndex;
    }

    final centersByPhase = <String, List<double>>{};
    for (int i = 0; i < phasesWithMatches.length; i++) {
      final phase = phasesWithMatches[i];
      final nodes = nodesByPhase[phase]!;
      if (i == 0) {
        centersByPhase[phase] = List.generate(
          nodes.length,
          (idx) => idx * (cardHeight + leafGap) + cardHeight / 2,
        );
      } else {
        final prevPhase = phasesWithMatches[i - 1];
        final prevCenters = centersByPhase[prevPhase]!;
        final isStandardHalving = nodes.length == (prevCenters.length / 2).ceil();
        if (isStandardHalving) {
          centersByPhase[phase] = List.generate(nodes.length, (idx) {
            final c1 = prevCenters.length > idx * 2 ? prevCenters[idx * 2] : 0.0;
            final c2 = prevCenters.length > idx * 2 + 1 ? prevCenters[idx * 2 + 1] : c1;
            return (c1 + c2) / 2;
          });
        } else {
          centersByPhase[phase] = List.generate(
            nodes.length,
            (idx) => idx * (cardHeight + leafGap) + cardHeight / 2,
          );
        }
      }
    }

    if (labelHeight != 0) {
      for (final phase in centersByPhase.keys) {
        centersByPhase[phase] = centersByPhase[phase]!.map((c) => c + labelHeight).toList();
      }
    }

    return BracketLayout._(
      phasesWithMatches: phasesWithMatches,
      nodesByPhase: nodesByPhase,
      centersByPhase: centersByPhase,
      connectorSourceIndices: connectorSourceIndices,
    );
  }
}
