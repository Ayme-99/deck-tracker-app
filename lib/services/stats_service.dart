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

  /// Evolución del win-rate partida a partida (issue #134): acumulado,
  /// y medias móviles de las últimas 5 y 10 partidas.
  Future<List<dynamic>> getDeckTimeline(String deckId) async {
    return await _api.get('/stats/deck/$deckId/timeline');
  }

  Future<Map<String, dynamic>> getGlobalOverview() async {
    return await _api.get('/stats/global/overview');
  }

  /// Evolución del win-rate global partida a partida (issue #88/#145),
  /// cruzando todos los mazos del usuario. Mismo shape que getDeckTimeline.
  Future<List<dynamic>> getGlobalTimeline() async {
    return await _api.get('/stats/global/timeline');
  }

  Future<List<dynamic>> getDeckRanking({int minMatches = 3, String sortBy = 'winRate'}) async {
    return await _api.get('/stats/global/ranking?minMatches=$minMatches&sortBy=$sortBy');
  }

  /// Stats agregadas contra cada rival, cruzando TODOS los mazos propios
  /// (issue #21) -- a diferencia de getDeckMatchups (dentro de un mazo).
  Future<List<dynamic>> getOpponentMatchups() async {
    return await _api.get('/stats/global/opponents');
  }
}