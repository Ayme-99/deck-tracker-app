import 'package:deck_tracker_app/services/api_service.dart';

import '../models/tournament.dart';
import '../models/tournament_match.dart';
import '../models/tournament_player.dart';

class TournamentService {
  final _api = ApiService();

  Future<List<Tournament>> getTournaments({int page = 1, int limit = 10}) async {
    final response = await _api.get('/tournaments?page=$page&limit=$limit');
    final tournamentsJson = response['data'] as List;
    return tournamentsJson.map((t) => Tournament.fromJson(t)).toList();
  }

  /// Devuelve el torneo junto a sus matches (el backend los incluye ya
  /// ordenados por phase/round en el propio payload, bajo la key 'matches')
  Future<Map<String, dynamic>> getTournamentById(String id) async {
    final response = await _api.get('/tournaments/$id');
    return {
      'tournament': Tournament.fromJson(response),
      'matches': response['matches'] as List,
    };
  }

  Future<Tournament> createTournament({
    required String name,
    required String mode,
    String format = 'Standard',
    DateTime? date,
    String? location,
    String? structure,
    String? deckId,
    String? notes,
    String eliminationFormat = 'single_match',
    bool thirdPlacePlayoff = false,
    bool leagueDoubleRound = false,
  }) async {
    final response = await _api.post('/tournaments', {
      'name': name,
      'mode': mode,
      'format': format,
      if (date != null) 'date': date.toIso8601String(),
      'location': location,
      'structure': structure,
      'deckId': deckId,
      'notes': notes,
      'eliminationFormat': eliminationFormat,
      'thirdPlacePlayoff': thirdPlacePlayoff,
      'leagueDoubleRound': leagueDoubleRound,
    });
    return Tournament.fromJson(response);
  }

  Future<Tournament> updateTournament(String id, Map<String, dynamic> updates) async {
    final response = await _api.put('/tournaments/$id', updates);
    return Tournament.fromJson(response);
  }

  Future<void> deleteTournament(String id) async {
    await _api.delete('/tournaments/$id');
  }

  Future<Tournament> addStandingSnapshot(
    String id, {
    int? points,
    int? position,
    String? notes,
  }) async {
    final response = await _api.post('/tournaments/$id/standing', {
      'points': points,
      'position': position,
      'notes': notes,
    });
    return Tournament.fromJson(response);
  }

  Future<Map<String, dynamic>> getTournamentSummary(String id) async {
    final response = await _api.get('/tournaments/$id/summary');
    return response as Map<String, dynamic>;
  }

  // --- Jugadores (modo hosted, issue #45) ---

  Future<TournamentPlayer> createPlayer(
    String tournamentId, {
    required String name,
    String? deckArchetype,
    bool isOrganizer = false,
    String? deckId,
  }) async {
    final response = await _api.post('/tournaments/$tournamentId/players', {
      'name': name,
      'deckArchetype': deckArchetype,
      'isOrganizer': isOrganizer,
      'deckId': ?deckId,
    });
    return TournamentPlayer.fromJson(response);
  }

  Future<List<TournamentPlayer>> getPlayers(String tournamentId) async {
    final response = await _api.get('/tournaments/$tournamentId/players') as List;
    return response.map((p) => TournamentPlayer.fromJson(p)).toList();
  }

  Future<TournamentPlayer> updatePlayer(
    String tournamentId,
    String playerId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _api.put('/tournaments/$tournamentId/players/$playerId', updates);
    return TournamentPlayer.fromJson(response);
  }

  Future<void> deletePlayer(String tournamentId, String playerId) async {
    await _api.delete('/tournaments/$tournamentId/players/$playerId');
  }

  // --- Rondas y emparejamientos (modo hosted, issue #46) ---

  Future<Map<String, dynamic>> generateSwissRound(String tournamentId) async {
    final response = await _api.post('/tournaments/$tournamentId/swiss-round', {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateEliminationBracket(
    String tournamentId, {
    required List<String> playerIds,
    bool seeded = false,
  }) async {
    final response = await _api.post('/tournaments/$tournamentId/elimination-bracket', {
      'playerIds': playerIds,
      'seeded': seeded,
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> assignPlayerGroups(String tournamentId, int groupSize) async {
    final response = await _api.post('/tournaments/$tournamentId/assign-groups', {'groupSize': groupSize});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateGroupStageRounds(String tournamentId) async {
    final response = await _api.post('/tournaments/$tournamentId/group-stage-rounds', {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateLeagueRounds(String tournamentId) async {
    final response = await _api.post('/tournaments/$tournamentId/league-rounds', {});
    return response as Map<String, dynamic>;
  }

  /// Cierra la fase de swiss (con topCut) o grupos (con qualifiersPerGroup)
  /// y genera la entrada a la eliminatoria. Solo se debe pasar uno de los dos.
  Future<Map<String, dynamic>> closePhaseToElimination(
    String tournamentId, {
    int? topCut,
    int? qualifiersPerGroup,
  }) async {
    final response = await _api.post('/tournaments/$tournamentId/close-phase', {
      'topCut': ?topCut,
      'qualifiersPerGroup': ?qualifiersPerGroup,
    });
    return response as Map<String, dynamic>;
  }

  /// Avanza el bracket de eliminatoria a la siguiente fase, emparejando
  /// los ganadores de `phase` en orden secuencial.
  Future<Map<String, dynamic>> advanceBracketRound(String tournamentId, String phase) async {
    final response = await _api.post('/tournaments/$tournamentId/advance-bracket', {'phase': phase});
    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getHostedStandings(String tournamentId) async {
    final response = await _api.get('/tournaments/$tournamentId/hosted-standings');
    return List<Map<String, dynamic>>.from(response['standings']);
  }

  Future<List<TournamentMatch>> getHostedMatches(String tournamentId) async {
    final response = await _api.get('/tournaments/$tournamentId/hosted-matches') as List;
    return response.map((m) => TournamentMatch.fromJson(m)).toList();
  }

  Future<Map<String, dynamic>> registerMatchResult(
    String tournamentId,
    String matchId, {
    int? player1Prizes,
    int? player2Prizes,
    String? winnerId,
    bool isDraw = false,
  }) async {
    final response = await _api.put('/tournaments/$tournamentId/hosted-matches/$matchId/result', {
      'player1Prizes': player1Prizes,
      'player2Prizes': player2Prizes,
      'winnerId': winnerId,
      'isDraw': isDraw,
    });
    return response as Map<String, dynamic>;
  }
}