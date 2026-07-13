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
  final String? tournamentId;
  final String? phase;
  final int? round;

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
    this.tournamentId,
    this.phase,
    this.round,
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
      tournamentId: json['tournamentId'],
      phase: json['phase'],
      round: json['round'],
    );
  }
}

// Etiquetas legibles para cada fase, reutilizables en toda la seccion de
// Torneos (detalle, formulario de partida...)
const kMatchPhaseLabels = {
  'group_stage': 'Fase de grupos',
  'swiss': 'Suiza',
  'round_of_16': 'Octavos',
  'quarterfinal': 'Cuartos',
  'semifinal': 'Semifinal',
  'final': 'Final',
  'league_round': 'Jornada',
};