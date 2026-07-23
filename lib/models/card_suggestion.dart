/// Carta real sugerida por el catalogo de pokemontcg.io (issue #12), para
/// poder elegir un cardId real en vez de un slug generado a mano del
/// nombre escrito.
class CardSuggestion {
  final String cardId;
  final String name;
  final String? set;
  final String? number;
  final String? image;

  CardSuggestion({
    required this.cardId,
    required this.name,
    this.set,
    this.number,
    this.image,
  });

  factory CardSuggestion.fromJson(Map<String, dynamic> json) {
    return CardSuggestion(
      cardId: json['cardId'],
      name: json['name'],
      set: json['set'],
      number: json['number'],
      image: json['image'],
    );
  }

  /// Texto mostrado en el desplegable del autocompletado: nombre + set
  /// (si se conoce), para distinguir reimpresiones de la misma carta.
  String get label => set != null ? '$name · $set' : name;
}
