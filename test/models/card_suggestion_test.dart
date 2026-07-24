import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/models/card_suggestion.dart';

CardSuggestion _suggestion({String? set, String? number}) {
  return CardSuggestion(cardId: 'ex9-4', name: 'Gardevoir', set: set, number: number);
}

void main() {
  group('CardSuggestion.label', () {
    test('sin set, muestra solo el nombre', () {
      expect(_suggestion().label, 'Gardevoir');
    });

    test('con set y numero, desambigua reimpresiones (issue #135)', () {
      expect(_suggestion(set: 'ex9', number: '4').label, 'Gardevoir · ex9 #4');
    });

    test('con set pero sin numero, muestra solo el set', () {
      expect(_suggestion(set: 'ex9').label, 'Gardevoir · ex9');
    });
  });
}
