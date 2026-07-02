import '../models/match.dart';
import 'api_service.dart';

class MatchService {
  final _api = ApiService();

  Future<List<Match>> getMatches({String? deckId, int page = 1, int limit = 20}) async {
    String endpoint = '/matches?page=$page&limit=$limit';
    if (deckId != null) endpoint += '&deckId=$deckId';

    final response = await _api.get(endpoint);
    final matchesJson = response['data'] as List;
    return matchesJson.map((m) => Match.fromJson(m)).toList();
  }

  Future<Match> getMatchById(String id) async {
    final response = await _api.get('/matches/$id');
    return Match.fromJson(response);
  }

  Future<Match> createMatch({
    required String deckId,
    required String opponentDeck,
    required int userPrizes,
    required int opponentPrizes,
    String endReason = 'normal',
    String? notes,
  }) async {
    final response = await _api.post('/matches', {
      'deckId': deckId,
      'opponentDeck': opponentDeck,
      'userPrizes': userPrizes,
      'opponentPrizes': opponentPrizes,
      'endReason': endReason,
      'notes': ?notes,
    });
    return Match.fromJson(response);
  }

  Future<Match> updateMatch(String id, Map<String, dynamic> updates) async {
    final response = await _api.put('/matches/$id', updates);
    return Match.fromJson(response);
  }

  Future<void> deleteMatch(String id) async {
    await _api.delete('/matches/$id');
  }

  Future<List<String>> getOpponentSuggestions(String query) async {
    final response = await _api.get('/matches/opponent-suggestions?q=$query');
    return List<String>.from(response);
  }
}