class StandingSnapshot {
  final DateTime date;
  final int? points;
  final int? position;
  final String? notes;

  StandingSnapshot({
    required this.date,
    this.points,
    this.position,
    this.notes,
  });

  factory StandingSnapshot.fromJson(Map<String, dynamic> json) {
    return StandingSnapshot(
      date: DateTime.parse(json['date']),
      points: json['points'],
      position: json['position'],
      notes: json['notes'],
    );
  }
}

class Tournament {
  final String id;
  final String name;
  final String format;
  final DateTime date;
  final String? location;
  final String mode; // 'tracked' | 'hosted'
  final String? structure; // 'swiss' | 'swiss_elimination' | 'groups_elimination' | 'elimination' | 'league'
  final String? deckId;
  final String status; // 'in_progress' | 'finished'
  final String? finalStanding;
  final List<StandingSnapshot> standingSnapshots;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // --- Configuracion especifica del modo hosted ---
  final String eliminationFormat; // 'single_match' | 'two_legs'
  final bool thirdPlacePlayoff;
  final bool leagueDoubleRound;

  Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.date,
    this.location,
    required this.mode,
    this.structure,
    this.deckId,
    required this.status,
    this.finalStanding,
    required this.standingSnapshots,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.eliminationFormat = 'single_match',
    this.thirdPlacePlayoff = false,
    this.leagueDoubleRound = false,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['_id'],
      name: json['name'],
      format: json['format'] ?? 'Standard',
      date: DateTime.parse(json['date']),
      location: json['location'],
      mode: json['mode'],
      structure: json['structure'],
      deckId: json['deckId'],
      status: json['status'] ?? 'in_progress',
      finalStanding: json['finalStanding'],
      standingSnapshots: json['standingSnapshots'] != null
          ? (json['standingSnapshots'] as List)
              .map((s) => StandingSnapshot.fromJson(s))
              .toList()
          : [],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      eliminationFormat: json['eliminationFormat'] ?? 'single_match',
      thirdPlacePlayoff: json['thirdPlacePlayoff'] ?? false,
      leagueDoubleRound: json['leagueDoubleRound'] ?? false,
    );
  }
}

// Etiquetas legibles para eliminationFormat
const kEliminationFormatLabels = {
  'single_match': 'Partido único',
  'two_legs': 'Ida y vuelta',
};

// Estructuras que incluyen una fase de eliminatoria directa en algun punto
// (para saber cuando mostrar la config de eliminationFormat/thirdPlacePlayoff)
const kStructuresWithElimination = {'elimination', 'swiss_elimination', 'groups_elimination'};

// Etiquetas legibles para las structure, reutilizables en toda la seccion
// de Torneos (listado, formulario, detalle...)
const kTournamentStructureLabels = {
  'swiss': 'Rondas suizas',
  'swiss_elimination': 'Suizas + eliminatoria',
  'groups_elimination': 'Fase de grupos + eliminatoria',
  'elimination': 'Eliminatoria directa',
  'league': 'Liga',
};

// Fases validas para cada structure, en el orden en que se juegan.
// Se usa al registrar una partida desde el detalle del torneo, para saber
// que fases ofrecer y si esa fase necesita numero de ronda (swiss/liga/grupos)
// o no (eliminatoria directa, donde la propia fase ya identifica la partida).
const kStructurePhases = {
  'swiss': ['swiss'],
  'elimination': ['round_of_16', 'quarterfinal', 'semifinal', 'final'],
  'swiss_elimination': ['swiss', 'round_of_16', 'quarterfinal', 'semifinal', 'final'],
  'groups_elimination': ['group_stage', 'round_of_16', 'quarterfinal', 'semifinal', 'final'],
  'league': ['league_round'],
};

// Fases en las que tiene sentido pedir un numero de ronda/jornada
const kRoundBasedPhases = {'swiss', 'group_stage', 'league_round'};