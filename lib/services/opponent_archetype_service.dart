import '../models/opponent_archetype.dart';
import 'api_service.dart';

class OpponentArchetypeService {
  final _api = ApiService();

  Future<OpponentArchetype> getByName(String name) async {
    final response = await _api.get('/opponent-archetypes/by-name?name=${Uri.encodeQueryComponent(name)}');
    return OpponentArchetype.fromJson(response);
  }

  Future<OpponentArchetype> upsert(String name, {String? sprite1, String? sprite2}) async {
    final response = await _api.post('/opponent-archetypes', {
      'name': name,
      'sprite1': sprite1,
      'sprite2': sprite2,
    });
    return OpponentArchetype.fromJson(response);
  }

  Future<List<OpponentArchetype>> getAll() async {
    final response = await _api.get('/opponent-archetypes');
    return (response as List).map((a) => OpponentArchetype.fromJson(a)).toList();
  }
}