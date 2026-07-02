class Match {
  final String id;
  final String deckId;
  final String opponentDeck;
  final int userPrizes;
  final int opponentPrizes;
  final String endReason;
  final String result;
  final String format;
  final String? notes;
  final DateTime playedAt;

  Match({
    required this.id,
    required this.deckId,
    required this.opponentDeck,
    required this.userPrizes,
    required this.opponentPrizes,
    required this.endReason,
    required this.result,
    required this.format,
    this.notes,
    required this.playedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['_id'],
      deckId: json['deckId'],
      opponentDeck: json['opponentDeck'],
      userPrizes: json['userPrizes'],
      opponentPrizes: json['opponentPrizes'],
      endReason: json['endReason'],
      result: json['result'],
      format: json['format'],
      notes: json['notes'],
      playedAt: DateTime.parse(json['playedAt']),
    );
  }
}