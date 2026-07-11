import 'package:deck_tracker_app/services/api_service.dart';

import '../models/tournament.dart';

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
}