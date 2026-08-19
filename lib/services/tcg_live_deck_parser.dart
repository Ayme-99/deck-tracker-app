/// Una carta extraida de un listado exportado de Pokémon TCG Live.
class ParsedDeckCard {
  final int quantity;
  final String name;
  final String category; // 'pokemon' | 'trainer' | 'energy'

  ParsedDeckCard({required this.quantity, required this.name, required this.category});
}

/// Parsea el formato de texto que exporta Pokémon TCG Live al copiar un mazo
/// (issue #176), para no tener que añadir las cartas una a una a mano.
///
/// Formato esperado (las secciones pueden venir en cualquier orden, y con o
/// sin acento/"Cards" en la cabecera):
/// ```
/// Pokémon: 12
/// 4 Charizard ex OBF 125
/// 2 Pidgey SVI 162
///
/// Trainer Cards: 35
/// 4 Ultra Ball PAL 160
///
/// Energy: 13
/// 8 Basic {R} Energy SVE 2
///
/// Total Cards: 60
/// ```
/// Logica pura (sin dependencias de Flutter), para poder testearla sin UI.
class TcgLiveDeckParser {
  TcgLiveDeckParser._();

  static final _sectionHeader = RegExp(
    r'^(pok[eé]mon|trainer|energy)s?\s*(cards?)?\s*:\s*\d+\s*$',
    caseSensitive: false,
  );

  static final _cardLine = RegExp(r'^(\d+)\s+(.+)$');

  // Codigo de set + numero al final de la linea (ej. "OBF 125", "SVE 2"),
  // que TCG Live siempre añade y que no aporta nada al nombre mostrado.
  static final _trailingSetCode = RegExp(r'\s+[A-Za-z0-9]{2,4}\s+[A-Za-z0-9]+$');

  static String? _categoryFor(String section) {
    final s = section.toLowerCase();
    if (s.startsWith('pok')) return 'pokemon';
    if (s.startsWith('train')) return 'trainer';
    if (s.startsWith('energy')) return 'energy';
    return null;
  }

  static List<ParsedDeckCard> parse(String text) {
    final cards = <ParsedDeckCard>[];
    String? currentCategory;

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final headerMatch = _sectionHeader.firstMatch(line);
      if (headerMatch != null) {
        currentCategory = _categoryFor(headerMatch.group(1)!);
        continue;
      }

      if (line.toLowerCase().startsWith('total cards')) continue;
      if (currentCategory == null) continue;

      final cardMatch = _cardLine.firstMatch(line);
      if (cardMatch == null) continue;

      final quantity = int.tryParse(cardMatch.group(1)!);
      if (quantity == null) continue;

      final name = cardMatch.group(2)!.trim().replaceFirst(_trailingSetCode, '').trim();
      if (name.isEmpty) continue;

      cards.add(ParsedDeckCard(quantity: quantity, name: name, category: currentCategory));
    }

    return cards;
  }
}
