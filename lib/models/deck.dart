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
  final DateTime? updatedAt;
  final String? sprite1;
  final String? sprite2;
  Deck({
    required this.id,
    required this.name,
    required this.format,
    required this.cards,
    required this.wins,
    required this.losses,
    required this.createdAt,
    this.updatedAt,
    this.sprite1,
    this.sprite2,
  });

  /// Fecha a usar para ordenar por "ultima actividad": updatedAt si existe,
  /// o createdAt como fallback (mazos antiguos creados antes de añadir timestamps).
  DateTime get lastActivityAt => updatedAt ?? createdAt;

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
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      sprite1: json['sprite1'],
      sprite2: json['sprite2'],
    );
  }

  /// Mismo formato que espera Deck.fromJson (issue #133: cache local),
  /// para poder guardar/recuperar un mazo sin depender de la API.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'format': format,
      'cards': cards.map((c) => c.toJson()).toList(),
      'wins': wins,
      'losses': losses,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sprite1': sprite1,
      'sprite2': sprite2,
    };
  }
}