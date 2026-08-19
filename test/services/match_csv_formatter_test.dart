import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/models/match.dart';
import 'package:deck_tracker_app/services/match_csv_formatter.dart';

Match _match({
  String opponentDeck = 'Charizard ex',
  String result = 'win',
  int userPrizes = 6,
  int opponentPrizes = 3,
  String? phase,
  int? round,
  String? notes,
}) {
  return Match(
    id: 'match-1',
    deckId: 'deck-1',
    opponentDeck: opponentDeck,
    userPrizes: userPrizes,
    opponentPrizes: opponentPrizes,
    endReason: 'normal',
    result: result,
    format: 'Standard',
    playedAt: DateTime(2026, 3, 5),
    phase: phase,
    round: round,
    notes: notes,
  );
}

void main() {
  group('MatchCsvFormatter.format', () {
    test('incluye la cabecera aunque no haya partidas', () {
      final csv = MatchCsvFormatter.format([]);
      expect(csv.trim(), 'Fecha,Rival,Resultado,Mis premios,Premios rival,Fase,Ronda,Notas');
    });

    test('formatea una fila con todos los campos', () {
      final csv = MatchCsvFormatter.format([
        _match(phase: 'swiss', round: 3, notes: 'Buena partida'),
      ]);
      final lines = csv.trim().split('\n');

      expect(lines[1], '2026-03-05,Charizard ex,Victoria,6,3,Suiza,3,Buena partida');
    });

    test('deja vacios fase/ronda/notas cuando no aplican', () {
      final csv = MatchCsvFormatter.format([_match()]);
      final lines = csv.trim().split('\n');

      expect(lines[1], '2026-03-05,Charizard ex,Victoria,6,3,,,');
    });

    test('etiqueta correctamente derrota y empate', () {
      final csv = MatchCsvFormatter.format([
        _match(result: 'loss'),
        _match(result: 'tie'),
      ]);
      final lines = csv.trim().split('\n');

      expect(lines[1], contains('Derrota'));
      expect(lines[2], contains('Empate'));
    });

    test('escapa campos con comas entre comillas dobles', () {
      final csv = MatchCsvFormatter.format([_match(opponentDeck: 'Pikachu, Raichu')]);
      final lines = csv.trim().split('\n');

      expect(lines[1], startsWith('2026-03-05,"Pikachu, Raichu",Victoria'));
    });

    test('escapa comillas dobles internas duplicandolas', () {
      final csv = MatchCsvFormatter.format([_match(notes: 'Dijo "gg" al final')]);
      final lines = csv.trim().split('\n');

      expect(lines[1], endsWith('"Dijo ""gg"" al final"'));
    });
  });
}
