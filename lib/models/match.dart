import '../l10n/app_localizations.dart';

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

  /// Mismo formato que espera Match.fromJson (issue #165: backup/restore),
  /// para poder guardar/recuperar una partida sin depender de la API.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'deckId': deckId,
      'opponentDeck': opponentDeck,
      'userPrizes': userPrizes,
      'opponentPrizes': opponentPrizes,
      'endReason': endReason,
      'result': result,
      'format': format,
      'notes': notes,
      'playedAt': playedAt.toIso8601String(),
      'tournamentId': tournamentId,
      'phase': phase,
      'round': round,
    };
  }
}

// Etiquetas legibles para cada fase, reutilizables en toda la seccion de
// Torneos (detalle, formulario de partida...)
Map<String, String> matchPhaseLabels(AppLocalizations l10n) => {
  'group_stage': l10n.matchPhaseGroupStage,
  'swiss': l10n.matchPhaseSwiss,
  'round_of_16': l10n.matchPhaseRoundOf16,
  'quarterfinal': l10n.matchPhaseQuarterfinal,
  'semifinal': l10n.matchPhaseSemifinal,
  'final': l10n.matchPhaseFinal,
  'league_round': l10n.matchPhaseLeagueRound,
};