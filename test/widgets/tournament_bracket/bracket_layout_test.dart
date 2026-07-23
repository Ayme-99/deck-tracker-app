import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/models/tournament_match.dart';
import 'package:deck_tracker_app/widgets/tournament_bracket/bracket_layout.dart';

const cardHeight = 69.0; // BracketConstants.cardHeight (32*2 + 1 + 4)
const leafGap = 14.0;

TournamentMatch match({
  required String id,
  required String phase,
  required String p1,
  String? p2,
  String? winnerId,
  String status = 'completed',
  bool isDraw = false,
  String leg = 'single',
  String? tiedMatchId,
  int? p1Prizes,
  int? p2Prizes,
  bool isThirdPlaceMatch = false,
}) {
  return TournamentMatch(
    id: id,
    phase: phase,
    player1Id: p1,
    player2Id: p2,
    winnerId: winnerId,
    status: status,
    isDraw: isDraw,
    leg: leg,
    tiedMatchId: tiedMatchId,
    player1Prizes: p1Prizes,
    player2Prizes: p2Prizes,
    isThirdPlaceMatch: isThirdPlaceMatch,
  );
}

void main() {
  group('BracketLayout.compute — caso vacio', () {
    test('sin partidas devuelve layout vacio', () {
      final layout = BracketLayout.compute(
        phaseOrder: const ['quarterfinal', 'semifinal', 'final'],
        matchesByPhase: const {},
        cardHeight: cardHeight,
        leafGap: leafGap,
      );

      expect(layout.phasesWithMatches, isEmpty);
      expect(layout.nodesByPhase, isEmpty);
      expect(layout.centersByPhase, isEmpty);
      expect(layout.connectorSourceIndices, isEmpty);
    });
  });

  group('BracketLayout.compute — bracket completo de 8 jugadores (sin byes)', () {
    late BracketLayout layout;

    setUp(() {
      final matchesByPhase = {
        'quarterfinal': [
          match(id: 'qf1', phase: 'quarterfinal', p1: 'p1', p2: 'p2', winnerId: 'p1'),
          match(id: 'qf2', phase: 'quarterfinal', p1: 'p3', p2: 'p4', winnerId: 'p3'),
          match(id: 'qf3', phase: 'quarterfinal', p1: 'p5', p2: 'p6', winnerId: 'p5'),
          match(id: 'qf4', phase: 'quarterfinal', p1: 'p7', p2: 'p8', winnerId: 'p7'),
        ],
        'semifinal': [
          match(id: 'sf1', phase: 'semifinal', p1: 'p1', p2: 'p3', winnerId: 'p1'),
          match(id: 'sf2', phase: 'semifinal', p1: 'p5', p2: 'p7', winnerId: 'p5'),
        ],
        'final': [
          match(id: 'f1', phase: 'final', p1: 'p1', p2: 'p5'),
        ],
      };

      layout = BracketLayout.compute(
        phaseOrder: const ['quarterfinal', 'semifinal', 'final'],
        matchesByPhase: matchesByPhase,
        cardHeight: cardHeight,
        leafGap: leafGap,
      );
    });

    test('conserva el orden de fases y el numero de nodos', () {
      expect(layout.phasesWithMatches, ['quarterfinal', 'semifinal', 'final']);
      expect(layout.nodesByPhase['quarterfinal']!.length, 4);
      expect(layout.nodesByPhase['semifinal']!.length, 2);
      expect(layout.nodesByPhase['final']!.length, 1);
    });

    test('reordena cuartos para que las 2 fuentes de cada semifinal queden adyacentes', () {
      final qf = layout.nodesByPhase['quarterfinal']!;
      // sf1 (p1 vs p3) debe alimentarse de los nodos 0 y 1; sf2 (p5 vs p7) de 2 y 3
      expect({qf[0].winnerId, qf[1].winnerId}, {'p1', 'p3'});
      expect({qf[2].winnerId, qf[3].winnerId}, {'p5', 'p7'});
    });

    test('connectorSourceIndices apunta a las 2 fuentes reales de cada nodo', () {
      expect(layout.connectorSourceIndices['semifinal'], [
        [0, 1],
        [2, 3],
      ]);
      expect(layout.connectorSourceIndices['final'], [
        [0, 1],
      ]);
    });

    test('centros: primera fase uniforme, resto por halving estandar', () {
      final qfCenters = layout.centersByPhase['quarterfinal']!;
      expect(qfCenters.length, 4);
      expect(qfCenters[1] - qfCenters[0], cardHeight + leafGap);

      final sfCenters = layout.centersByPhase['semifinal']!;
      expect(sfCenters[0], (qfCenters[0] + qfCenters[1]) / 2);
      expect(sfCenters[1], (qfCenters[2] + qfCenters[3]) / 2);

      final finalCenters = layout.centersByPhase['final']!;
      expect(finalCenters[0], (sfCenters[0] + sfCenters[1]) / 2);
    });

    test('labelHeight desplaza todos los centros por igual', () {
      final withLabel = BracketLayout.compute(
        phaseOrder: const ['quarterfinal', 'semifinal', 'final'],
        matchesByPhase: {
          'quarterfinal': layout.nodesByPhase['quarterfinal']!.map((n) => n.legs.first).toList(),
          'semifinal': [
            match(id: 'sf1', phase: 'semifinal', p1: 'p1', p2: 'p3', winnerId: 'p1'),
            match(id: 'sf2', phase: 'semifinal', p1: 'p5', p2: 'p7', winnerId: 'p5'),
          ],
          'final': [match(id: 'f1', phase: 'final', p1: 'p1', p2: 'p5')],
        },
        cardHeight: cardHeight,
        leafGap: leafGap,
        labelHeight: 24,
      );
      expect(withLabel.centersByPhase['final']![0], layout.centersByPhase['final']![0] + 24);
    });
  });

  group('BracketLayout.compute — bracket completo de 16 jugadores (sin byes)', () {
    test('4 fases encadenadas correctamente por winnerId', () {
      final round16 = List.generate(
        8,
        (i) => match(
          id: 'r16_$i',
          phase: 'round_of_16',
          p1: 'p${i * 2 + 1}',
          p2: 'p${i * 2 + 2}',
          winnerId: 'p${i * 2 + 1}',
        ),
      );
      final quarterfinal = List.generate(
        4,
        (i) => match(
          id: 'qf_$i',
          phase: 'quarterfinal',
          p1: round16[i * 2].winnerId!,
          p2: round16[i * 2 + 1].winnerId!,
          winnerId: round16[i * 2].winnerId,
        ),
      );
      final semifinal = [
        match(id: 'sf_0', phase: 'semifinal', p1: quarterfinal[0].winnerId!, p2: quarterfinal[1].winnerId!, winnerId: quarterfinal[0].winnerId),
        match(id: 'sf_1', phase: 'semifinal', p1: quarterfinal[2].winnerId!, p2: quarterfinal[3].winnerId!, winnerId: quarterfinal[2].winnerId),
      ];
      final finalMatch = match(id: 'f_0', phase: 'final', p1: semifinal[0].winnerId!, p2: semifinal[1].winnerId!);

      final layout = BracketLayout.compute(
        phaseOrder: const ['round_of_16', 'quarterfinal', 'semifinal', 'final'],
        matchesByPhase: {
          'round_of_16': round16,
          'quarterfinal': quarterfinal,
          'semifinal': semifinal,
          'final': [finalMatch],
        },
        cardHeight: cardHeight,
        leafGap: leafGap,
      );

      expect(layout.phasesWithMatches, ['round_of_16', 'quarterfinal', 'semifinal', 'final']);
      expect(layout.nodesByPhase['round_of_16']!.length, 8);
      expect(layout.connectorSourceIndices['quarterfinal']!.every((s) => s.length == 2), isTrue);
      expect(layout.connectorSourceIndices['semifinal']!.every((s) => s.length == 2), isTrue);
      expect(layout.connectorSourceIndices['final']!.single.length, 2);
    });
  });

  group('BracketLayout.compute — ida/vuelta + muerte subita agrupadas en un nodo', () {
    test('agrupa las 3 partidas via tiedMatchId y calcula ganador por muerte subita', () {
      final firstLeg = match(
        id: 'leg1',
        phase: 'final',
        p1: 'p1',
        p2: 'p2',
        status: 'completed',
        leg: 'first_leg',
        p1Prizes: 6,
        p2Prizes: 6,
        tiedMatchId: 'leg2',
      );
      final secondLeg = match(
        id: 'leg2',
        phase: 'final',
        p1: 'p2',
        p2: 'p1',
        status: 'completed',
        leg: 'second_leg',
        p1Prizes: 6,
        p2Prizes: 6,
        tiedMatchId: 'leg1',
      );
      final suddenDeath = match(
        id: 'leg3',
        phase: 'final',
        p1: 'p1',
        p2: 'p2',
        status: 'completed',
        leg: 'sudden_death',
        winnerId: 'p1',
        tiedMatchId: 'leg1',
      );

      final layout = BracketLayout.compute(
        phaseOrder: const ['final'],
        matchesByPhase: {
          'final': [firstLeg, secondLeg, suddenDeath],
        },
        cardHeight: cardHeight,
        leafGap: leafGap,
      );

      expect(layout.nodesByPhase['final']!.length, 1);
      final node = layout.nodesByPhase['final']!.single;
      expect(node.isTwoLegs, isTrue);
      expect(node.legs.length, 3);
      expect(node.winnerId, 'p1');
      expect(node.resultLabel, 'Agregado + muerte súbita');
    });
  });

  group('BracketLayout.compute — bracket de 32 y 64 jugadores (issue #92)', () {
    /// Genera un bracket completo (potencia de 2, sin byes) con las fases
    /// indicadas, encadenando siempre el ganador de player1 en cada partida.
    Map<String, List<TournamentMatch>> fullBracket(List<String> phases, int firstRoundPlayers) {
      final matchesByPhase = <String, List<TournamentMatch>>{};
      var ids = List.generate(firstRoundPlayers, (i) => 'p${i + 1}');

      for (final phase in phases) {
        final roundMatches = <TournamentMatch>[];
        for (var i = 0; i < ids.length; i += 2) {
          roundMatches.add(match(
            id: '${phase}_${i ~/ 2}',
            phase: phase,
            p1: ids[i],
            p2: ids[i + 1],
            winnerId: ids[i],
          ));
        }
        matchesByPhase[phase] = roundMatches;
        ids = roundMatches.map((m) => m.winnerId!).toList();
      }
      return matchesByPhase;
    }

    test('32 jugadores: round_of_32 -> round_of_16 -> cuartos -> semis -> final', () {
      const phases = ['round_of_32', 'round_of_16', 'quarterfinal', 'semifinal', 'final'];
      final layout = BracketLayout.compute(
        phaseOrder: kEliminationPhaseOrder,
        matchesByPhase: fullBracket(phases, 32),
        cardHeight: cardHeight,
        leafGap: leafGap,
      );

      expect(layout.phasesWithMatches, phases);
      expect(layout.nodesByPhase['round_of_32']!.length, 16);
      for (final phase in phases.skip(1)) {
        expect(layout.connectorSourceIndices[phase]!.every((s) => s.length == 2), isTrue);
      }
    });

    test('64 jugadores: round_of_64 hasta final, las 6 fases completas', () {
      const phases = ['round_of_64', 'round_of_32', 'round_of_16', 'quarterfinal', 'semifinal', 'final'];
      final layout = BracketLayout.compute(
        phaseOrder: kEliminationPhaseOrder,
        matchesByPhase: fullBracket(phases, 64),
        cardHeight: cardHeight,
        leafGap: leafGap,
      );

      expect(layout.phasesWithMatches, phases);
      expect(layout.nodesByPhase['round_of_64']!.length, 32);
      expect(layout.nodesByPhase['final']!.length, 1);
      for (final phase in phases.skip(1)) {
        expect(layout.connectorSourceIndices[phase]!.every((s) => s.length == 2), isTrue);
      }
    });
  });

  group('BracketLayout.compute — ronda previa reducida (bye real, relacion 1:1)', () {
    test('nodo siguiente con un solo jugador conocido (bye) solo tiene 1 fuente conectable', () {
      // p3 recibio un bye y avanza directo a semifinal sin jugar cuartos;
      // el otro hueco de esa semifinal (player2Id null) no tiene fuente que dibujar.
      final quarterfinal = [
        match(id: 'qf1', phase: 'quarterfinal', p1: 'p1', p2: 'p2', winnerId: 'p1'),
      ];
      final semifinal = [
        match(id: 'sf1', phase: 'semifinal', p1: 'p1', p2: null),
      ];

      final layout = BracketLayout.compute(
        phaseOrder: const ['quarterfinal', 'semifinal'],
        matchesByPhase: {'quarterfinal': quarterfinal, 'semifinal': semifinal},
        cardHeight: cardHeight,
        leafGap: leafGap,
      );

      expect(layout.connectorSourceIndices['semifinal'], [
        [0],
      ]);
      // reparto uniforme (no halving estandar: 2 nodos de cuartos tras
      // padding vs 1 de semifinal no es exactamente el doble)
      final qfCenters = layout.centersByPhase['quarterfinal']!;
      expect(qfCenters.length, 2);
      expect(qfCenters[1] - qfCenters[0], cardHeight + leafGap);
    });
  });
}
