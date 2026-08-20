import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/models/tournament.dart';

void main() {
  group('parseFinalStanding', () {
    test('parsea un texto valido', () {
      expect(parseFinalStanding('3º de 16'), (3, 16));
    });

    test('devuelve null si es null', () {
      expect(parseFinalStanding(null), isNull);
    });

    test('devuelve null si esta vacio', () {
      expect(parseFinalStanding(''), isNull);
    });

    test('devuelve null si no sigue el formato esperado', () {
      expect(parseFinalStanding('primero de dieciseis'), isNull);
      expect(parseFinalStanding('3 de 16'), isNull);
      expect(parseFinalStanding('3º de'), isNull);
    });
  });

  group('formatFinalStanding', () {
    test('genera el texto en el formato esperado', () {
      expect(formatFinalStanding(3, 16), '3º de 16');
    });

    test('el resultado se puede volver a parsear (round-trip)', () {
      final formatted = formatFinalStanding(1, 8);
      expect(parseFinalStanding(formatted), (1, 8));
    });
  });
}
