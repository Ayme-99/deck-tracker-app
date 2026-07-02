class DeckCard {
  final String cardId;
  final String name;
  final int quantity;
  final String category;

  DeckCard({
    required this.cardId,
    required this.name,
    required this.quantity,
    required this.category,
  });

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    return DeckCard(
      cardId: json['cardId'],
      name: json['name'],
      quantity: json['quantity'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'name': name,
      'quantity': quantity,
      'category': category,
    };
  }
}

class Deck {
  final String id;
  final String name;
  final String format;
  final List<DeckCard> cards;
  final int wins;
  final int losses;
  final DateTime createdAt;

  Deck({
    required this.id,
    required this.name,
    required this.format,
    required this.cards,
    required this.wins,
    required this.losses,
    required this.createdAt,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['_id'],
      name: json['name'],
      format: json['format'],
      cards: (json['cards'] as List)
          .map((c) => DeckCard.fromJson(c))
          .toList(),
      wins: json['wins'],
      losses: json['losses'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}