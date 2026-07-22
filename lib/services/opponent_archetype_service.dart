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

  /// Edita el nombre y/o los sprites de un rival ya afrontado. Si [newName]
  /// difiere de [name], el backend propaga el cambio a las partidas ya
  /// registradas para conservar el historial.
  Future<OpponentArchetype> update(
    String name, {
    String? newName,
    String? sprite1,
    String? sprite2,
  }) async {
    final response = await _api.patch('/opponent-archetypes', {
      'name': name,
      'newName': ?newName,
      'sprite1': sprite1,
      'sprite2': sprite2,
    });
    return OpponentArchetype.fromJson(response);
  }

  /// Borra un rival y, en cascada, todas las partidas registradas contra el.
  Future<void> delete(String name) async {
    await _api.delete('/opponent-archetypes', body: {'name': name});
  }
}