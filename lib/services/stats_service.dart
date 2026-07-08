import 'api_service.dart';

class StatsService {
  final _api = ApiService();

  Future<Map<String, dynamic>> getDeckOverview(String deckId) async {
    return await _api.get('/stats/deck/$deckId/overview');
  }

  Future<List<dynamic>> getDeckMatchups(String deckId) async {
    return await _api.get('/stats/deck/$deckId/matchups');
  }

  Future<Map<String, dynamic>> getDeckStreak(String deckId) async {
    return await _api.get('/stats/deck/$deckId/streak');
  }

  Future<Map<String, dynamic>> getGlobalOverview() async {
    return await _api.get('/stats/global/overview');
  }

  Future<List<dynamic>> getDeckRanking({int minMatches = 3, String sortBy = 'winRate'}) async {
    return await _api.get('/stats/global/ranking?minMatches=$minMatches&sortBy=$sortBy');
  }
}