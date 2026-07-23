class TournamentMatch {
  final String id;
  final String phase;
  final int? round;
  final String player1Id;
  final String? player2Id;
  final String? winnerId;
  final String status; // 'pending' | 'completed'
  final String? notes;
  final int? player1Prizes;
  final int? player2Prizes;
  final bool isDraw;
  final String leg; // 'single' | 'first_leg' | 'second_leg' | 'sudden_death'
  final String? tiedMatchId;
  final bool isThirdPlaceMatch;

  TournamentMatch({
    required this.id,
    required this.phase,
    this.round,
    required this.player1Id,
    this.player2Id,
    this.winnerId,
    required this.status,
    this.notes,
    this.player1Prizes,
    this.player2Prizes,
    required this.isDraw,
    required this.leg,
    this.tiedMatchId,
    this.isThirdPlaceMatch = false,
  });

  bool get isBye => player2Id == null;

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['_id'],
      phase: json['phase'],
      round: json['round'],
      player1Id: json['player1Id'] is Map ? json['player1Id']['_id'] : json['player1Id'],
      player2Id: json['player2Id'] == null
          ? null
          : (json['player2Id'] is Map ? json['player2Id']['_id'] : json['player2Id']),
      winnerId: json['winnerId'] == null
          ? null
          : (json['winnerId'] is Map ? json['winnerId']['_id'] : json['winnerId']),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      player1Prizes: json['player1Prizes'],
      player2Prizes: json['player2Prizes'],
      isDraw: json['isDraw'] ?? false,
      leg: json['leg'] ?? 'single',
      tiedMatchId: json['tiedMatchId'] == null
          ? null
          : (json['tiedMatchId'] is Map ? json['tiedMatchId']['_id'] : json['tiedMatchId']),
      isThirdPlaceMatch: json['isThirdPlaceMatch'] ?? false,
    );
  }
}

// Etiquetas legibles para cada fase (comparte semantica con kMatchPhaseLabels
// de match.dart, duplicado aqui para no acoplar hosted a tracked)
const kTournamentMatchPhaseLabels = {
  'group_stage': 'Fase de grupos',
  'swiss': 'Suiza',
  'round_of_64': 'Fase de 64',
  'round_of_32': 'Dieciseisavos',
  'round_of_16': 'Octavos',
  'quarterfinal': 'Cuartos',
  'semifinal': 'Semifinal',
  'final': 'Final',
  'league_round': 'Jornada',
};

// Orden de fases de eliminatoria, de mayor a menor tamaño de bracket
// (ampliado hasta 64 jugadores, issue #92)
const kEliminationPhaseOrder = ['round_of_64', 'round_of_32', 'round_of_16', 'quarterfinal', 'semifinal', 'final'];