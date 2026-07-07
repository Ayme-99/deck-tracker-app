import 'api_service.dart';

class PokemonService {
  final _api = ApiService();

  Future<List<String>> searchSpecies(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _api.get('/pokemon/search?q=$query');
    return List<String>.from(response);
  }

  Future<String?> getSprite(String speciesName) async {
    try {
      final response = await _api.get('/pokemon/sprite/$speciesName');
      return response['spriteUrl'] as String?;
    } catch (_) {
      return null; // 404 u otro error: sin sprite disponible
    }
  }
}