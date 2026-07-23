import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/models/deck.dart';
import 'package:deck_tracker_app/models/opponent_archetype.dart';
import 'package:deck_tracker_app/services/archetype_sprite_lookup.dart';

Deck _deck(String name, {String? sprite1, String? sprite2}) {
  return Deck(
    id: 'deck-$name',
    name: name,
    format: 'Standard',
    cards: const [],
    wins: 0,
    losses: 0,
    createdAt: DateTime(2026, 1, 1),
    sprite1: sprite1,
    sprite2: sprite2,
  );
}

OpponentArchetype _archetype(String name, {String? sprite1, String? sprite2}) {
  return OpponentArchetype(name: name, sprite1: sprite1, sprite2: sprite2);
}

void main() {
  group('ArchetypeSpriteLookup.spritesForName', () {
    test('devuelve null,null si el nombre es null', () {
      const lookup = ArchetypeSpriteLookup(decks: [], archetypes: []);
      expect(lookup.spritesForName(null), (null, null));
    });

    test('devuelve null,null si el nombre esta vacio', () {
      const lookup = ArchetypeSpriteLookup(decks: [], archetypes: []);
      expect(lookup.spritesForName(''), (null, null));
    });

    test('encuentra sprites de un mazo propio por nombre', () {
      final lookup = ArchetypeSpriteLookup(
        decks: [_deck('Charizard ex', sprite1: 's1', sprite2: 's2')],
        archetypes: const [],
      );
      expect(lookup.spritesForName('Charizard ex'), ('s1', 's2'));
    });

    test('encuentra sprites de un arquetipo rival por nombre', () {
      final lookup = ArchetypeSpriteLookup(
        decks: const [],
        archetypes: [_archetype('Lost Box', sprite1: 'r1', sprite2: 'r2')],
      );
      expect(lookup.spritesForName('Lost Box'), ('r1', 'r2'));
    });

    test('devuelve null,null si el nombre no coincide con nada', () {
      final lookup = ArchetypeSpriteLookup(
        decks: [_deck('Charizard ex', sprite1: 's1')],
        archetypes: [_archetype('Lost Box', sprite1: 'r1')],
      );
      expect(lookup.spritesForName('Gardevoir ex'), (null, null));
    });

    test('si el nombre coincide en ambas listas, ganan los mazos propios', () {
      final lookup = ArchetypeSpriteLookup(
        decks: [_deck('Charizard ex', sprite1: 'mio1', sprite2: 'mio2')],
        archetypes: [_archetype('Charizard ex', sprite1: 'rival1', sprite2: 'rival2')],
      );
      expect(lookup.spritesForName('Charizard ex'), ('mio1', 'mio2'));
    });
  });
}
