import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/models/match.dart';
import 'package:deck_tracker_app/models/tournament.dart';
import 'package:deck_tracker_app/services/share_text_formatter.dart';

Match _match({
  String result = 'win',
  String? phase,
  int? round,
}) {
  return Match(
    id: 'match-1',
    deckId: 'deck-1',
    opponentDeck: 'Charizard ex',
    userPrizes: 6,
    opponentPrizes: 3,
    endReason: 'prizes',
    result: result,
    format: 'Standard',
    playedAt: DateTime(2026, 3, 15),
    phase: phase,
    round: round,
  );
}

Tournament _tournament({String? finalStanding}) {
  return Tournament(
    id: 'tournament-1',
    name: 'Liga Local Marzo',
    format: 'Standard',
    date: DateTime(2026, 3, 1),
    mode: 'tracked',
    structure: 'swiss',
    status: 'finished',
    finalStanding: finalStanding,
    standingSnapshots: const [],
    createdAt: DateTime(2026, 3, 1),
  );
}

void main() {
  group('ShareTextFormatter.formatMatch', () {
    test('incluye el nombre del mazo cuando se proporciona', () {
      final text = ShareTextFormatter.formatMatch(_match(), deckName: 'Gardevoir ex');

      expect(text, contains('Gardevoir ex vs Charizard ex'));
      expect(text, contains('Victoria · 6-3'));
      expect(text, contains('15/03/2026'));
    });

    test('omite el nombre del mazo cuando no se proporciona', () {
      final text = ShareTextFormatter.formatMatch(_match());

      expect(text, contains('vs Charizard ex'));
      expect(text, isNot(contains('Gardevoir')));
    });

    test('incluye fase y ronda cuando la partida pertenece a un torneo', () {
      final text = ShareTextFormatter.formatMatch(_match(phase: 'swiss', round: 3));

      expect(text, contains('Suiza (ronda 3)'));
    });

    test('etiqueta correctamente derrota y empate', () {
      expect(ShareTextFormatter.formatMatch(_match(result: 'loss')), contains('Derrota'));
      expect(ShareTextFormatter.formatMatch(_match(result: 'tie')), contains('Empate'));
    });
  });

  group('ShareTextFormatter.formatTournamentSummary', () {
    test('incluye nombre, estructura, record y posicion final', () {
      final summary = {
        'overall': {'wins': 4, 'losses': 1, 'ties': 0, 'winRate': 80},
      };

      final text = ShareTextFormatter.formatTournamentSummary(
        _tournament(finalStanding: '1er puesto'),
        summary,
      );

      expect(text, contains('Liga Local Marzo'));
      expect(text, contains('Rondas suizas'));
      expect(text, contains('4V-1D-0E · 80% win rate'));
      expect(text, contains('🏆 1er puesto'));
    });

    test('omite la linea de posicion final cuando no hay finalStanding', () {
      final summary = {
        'overall': {'wins': 2, 'losses': 2, 'ties': 1, 'winRate': 40},
      };

      final text = ShareTextFormatter.formatTournamentSummary(_tournament(), summary);

      expect(text, isNot(contains('🏆')));
    });
  });
}
