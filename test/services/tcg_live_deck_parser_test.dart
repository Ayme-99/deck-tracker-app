import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/services/tcg_live_deck_parser.dart';

void main() {
  group('TcgLiveDeckParser.parse', () {
    test('parsea las 3 secciones con cabeceras estandar', () {
      const text = '''
Pokémon: 2
4 Charizard ex OBF 125
2 Pidgey SVI 162

Trainer: 1
4 Ultra Ball PAL 160

Energy: 1
8 Basic {R} Energy SVE 2

Total Cards: 60
''';

      final cards = TcgLiveDeckParser.parse(text);

      expect(cards.length, 4);
      expect(cards[0].quantity, 4);
      expect(cards[0].name, 'Charizard ex');
      expect(cards[0].category, 'pokemon');
      expect(cards[1].name, 'Pidgey');
      expect(cards[2].name, 'Ultra Ball');
      expect(cards[2].category, 'trainer');
      expect(cards[3].category, 'energy');
    });

    test('acepta cabeceras sin acento y con "Cards"', () {
      const text = '''
Pokemon Cards: 1
1 Pikachu SVI 54

Trainer Card: 1
1 Iono PAL 185
''';

      final cards = TcgLiveDeckParser.parse(text);

      expect(cards.length, 2);
      expect(cards[0].category, 'pokemon');
      expect(cards[1].category, 'trainer');
    });

    test('quita el codigo de set y numero del nombre', () {
      final cards = TcgLiveDeckParser.parse('Pokémon: 1\n1 Mega Lucario ex M23 1');
      expect(cards.single.name, 'Mega Lucario ex');
    });

    test('ignora lineas en blanco y "Total Cards"', () {
      const text = '''
Pokémon: 1
1 Eevee SVI 130

Total Cards: 1
''';
      final cards = TcgLiveDeckParser.parse(text);
      expect(cards.length, 1);
    });

    test('ignora lineas antes de la primera cabecera de seccion', () {
      const text = '''
Algo que no es una cabecera
1 Eevee SVI 130

Pokémon: 1
1 Pikachu SVI 54
''';
      final cards = TcgLiveDeckParser.parse(text);

      expect(cards.length, 1);
      expect(cards.single.name, 'Pikachu');
    });

    test('devuelve lista vacia con texto sin formato reconocible', () {
      expect(TcgLiveDeckParser.parse('esto no es un mazo'), isEmpty);
    });

    test('devuelve lista vacia con texto vacio', () {
      expect(TcgLiveDeckParser.parse(''), isEmpty);
    });
  });
}
