import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deck_tracker_app/models/deck.dart';
import 'package:deck_tracker_app/services/deck_cache_service.dart';

Deck _deck(String id, String name) {
  return Deck(
    id: id,
    name: name,
    format: 'Standard',
    cards: const [],
    wins: 3,
    losses: 1,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 2, 1),
    sprite1: 'sprite-a',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeckCacheService', () {
    test('load devuelve null si no hay nada guardado', () async {
      final result = await DeckCacheService().load();
      expect(result, isNull);
    });

    test('guarda y recupera mazos + overviews sin perder datos', () async {
      final service = DeckCacheService();
      final decks = [_deck('deck-1', 'Gardevoir ex'), _deck('deck-2', 'Charizard ex')];
      final overviews = {
        'deck-1': {'wins': 3, 'losses': 1, 'ties': 0},
        'deck-2': {'wins': 5, 'losses': 2, 'ties': 1},
      };

      await service.save(decks, overviews);
      final result = await service.load();

      expect(result, isNotNull);
      expect(result!.decks.map((d) => d.id), ['deck-1', 'deck-2']);
      expect(result.decks.first.name, 'Gardevoir ex');
      expect(result.decks.first.sprite1, 'sprite-a');
      expect(result.overviews['deck-1'], {'wins': 3, 'losses': 1, 'ties': 0});
      expect(result.overviews['deck-2'], {'wins': 5, 'losses': 2, 'ties': 1});
    });

    test('una segunda llamada a save sobreescribe el snapshot anterior', () async {
      final service = DeckCacheService();
      await service.save([_deck('deck-1', 'Viejo')], {'deck-1': {'wins': 1}});
      await service.save([_deck('deck-2', 'Nuevo')], {'deck-2': {'wins': 9}});

      final result = await service.load();

      expect(result!.decks.map((d) => d.id), ['deck-2']);
      expect(result.overviews.containsKey('deck-1'), isFalse);
    });

    test('load devuelve null si el JSON guardado esta corrupto', () async {
      SharedPreferences.setMockInitialValues({
        'cache_deck_list_snapshot_v1': 'esto no es json valido',
      });

      final result = await DeckCacheService().load();
      expect(result, isNull);
    });
  });
}
