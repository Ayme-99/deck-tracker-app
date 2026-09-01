import 'tournament_match.dart' show kEliminationPhaseOrder;
import '../l10n/app_localizations.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'points': points,
      'position': position,
      'notes': notes,
    };
  }
}

class Tournament {
  final String id;
  // Issue #257: id del dueño del torneo, para distinguir "mis torneos" de
  // los torneos hosted donde participo como invitado (server#102).
  final String userId;
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
    required this.userId,
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
      // Ausente en backups antiguos (issue #165, previos a la #257): no se
      // usa para nada en ese flujo (restoreBackup no lo lee), asi que un
      // valor vacio es un fallback seguro en vez de reventar el parseo.
      userId: json['userId'] ?? '',
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

  /// Mismo formato que espera Tournament.fromJson (issue #165: backup/
  /// restore), para poder guardar/recuperar un torneo sin depender de la API.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'name': name,
      'format': format,
      'date': date.toIso8601String(),
      'location': location,
      'mode': mode,
      'structure': structure,
      'deckId': deckId,
      'status': status,
      'finalStanding': finalStanding,
      'standingSnapshots': standingSnapshots.map((s) => s.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'eliminationFormat': eliminationFormat,
      'thirdPlacePlayoff': thirdPlacePlayoff,
      'leagueDoubleRound': leagueDoubleRound,
    };
  }
}

// Etiquetas legibles para eliminationFormat
Map<String, String> eliminationFormatLabels(AppLocalizations l10n) => {
  'single_match': l10n.eliminationFormatSingleMatch,
  'two_legs': l10n.eliminationFormatTwoLegs,
};

// Estructuras que incluyen una fase de eliminatoria directa en algun punto
// (para saber cuando mostrar la config de eliminationFormat/thirdPlacePlayoff)
const kStructuresWithElimination = {'elimination', 'swiss_elimination', 'groups_elimination'};

// Etiquetas legibles para las structure, reutilizables en toda la seccion
// de Torneos (listado, formulario, detalle...)
Map<String, String> tournamentStructureLabels(AppLocalizations l10n) => {
  'swiss': l10n.tournamentStructureSwiss,
  'swiss_elimination': l10n.tournamentStructureSwissElimination,
  'groups_elimination': l10n.tournamentStructureGroupsElimination,
  'elimination': l10n.tournamentStructureElimination,
  'league': l10n.tournamentStructureLeague,
};

// Fases validas para cada structure, en el orden en que se juegan.
// Se usa al registrar una partida desde el detalle del torneo, para saber
// que fases ofrecer y si esa fase necesita numero de ronda (swiss/liga/grupos)
// o no (eliminatoria directa, donde la propia fase ya identifica la partida).
const kStructurePhases = {
  'swiss': ['swiss'],
  'elimination': [...kEliminationPhaseOrder],
  'swiss_elimination': ['swiss', ...kEliminationPhaseOrder],
  'groups_elimination': ['group_stage', ...kEliminationPhaseOrder],
  'league': ['league_round'],
};

// Fases en las que tiene sentido pedir un numero de ronda/jornada
const kRoundBasedPhases = {'swiss', 'group_stage', 'league_round'};

// Formato de Tournament.finalStanding: "3º de 16". Centralizado aqui (issue
// #187) -- antes el regex vivia duplicado en tournament_detail_screen.dart
// (donde se genera) y tournaments_screen.dart (donde se parsea para
// ordenar), sin validacion de que ambos textos coincidieran.
final RegExp kFinalStandingPattern = RegExp(r'^(\d+)º de (\d+)$');

/// Devuelve (posicion, total) si [finalStanding] tiene el formato esperado,
/// o null si es null/vacio/no coincide.
(int, int)? parseFinalStanding(String? finalStanding) {
  if (finalStanding == null) return null;
  final match = kFinalStandingPattern.firstMatch(finalStanding);
  if (match == null) return null;
  final position = int.tryParse(match.group(1)!);
  final total = int.tryParse(match.group(2)!);
  if (position == null || total == null) return null;
  return (position, total);
}

String formatFinalStanding(int position, int total) => '$positionº de $total';
