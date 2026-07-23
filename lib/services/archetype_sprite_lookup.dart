import '../models/deck.dart';
import '../models/opponent_archetype.dart';

/// Busca los sprites guardados para un nombre de mazo/arquetipo (issue #51),
/// mirando primero entre los mazos propios y, si no hay coincidencia, entre
/// los arquetipos rivales ya guardados. Extraida (issue #118) de 3 copias
/// identicas que vivian como metodo privado en tournament_players_screen.dart,
/// tournament_rounds_screen.dart y tournament_standings_screen.dart.
class ArchetypeSpriteLookup {
  final List<Deck> decks;
  final List<OpponentArchetype> archetypes;

  const ArchetypeSpriteLookup({required this.decks, required this.archetypes});

  (String?, String?) spritesForName(String? name) {
    if (name == null || name.isEmpty) return (null, null);
    for (final d in decks) {
      if (d.name == name) return (d.sprite1, d.sprite2);
    }
    for (final a in archetypes) {
      if (a.name == name) return (a.sprite1, a.sprite2);
    }
    return (null, null);
  }
}
