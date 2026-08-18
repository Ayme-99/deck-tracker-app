import 'package:deck_tracker_app/services/api_service.dart';

import '../models/deck.dart';

class DeckService {
  final _api = ApiService();

  // FIX (issue #97): el limite por defecto era 10, y deck_list_screen
  // llama a getDecks() sin argumentos -- solo se veian los 10 mazos mas
  // recientes (backend ordena por createdAt desc), los demas "desaparecian"
  // segun se creaban mazos nuevos. Se sube el limite por defecto a un
  // valor que cubra cualquier uso real, sin necesitar paginacion/scroll
  // infinito completo para un caso de uso tan acotado (mazos de un usuario).
  Future<List<Deck>> getDecks({int page = 1, int limit = 1000}) async {
    final response = await _api.get('/decks?page=$page&limit=$limit');
    final decksJson = response['data'] as List;
    return decksJson.map((d) => Deck.fromJson(d)).toList();
  }

  Future<Deck> getDeckById(String id) async {
    final response = await _api.get('/decks/$id');
    return Deck.fromJson(response);
  }

  // El campo format ya no se pide en el cliente (issue #163): el meta rota
  // cada año y mantenerlo actualizado en la UI no compensaba. El backend
  // sigue teniendo el campo (default 'Standard') por si se retoma mas
  // adelante, simplemente no se envia desde aqui.
  Future<Deck> createDeck(
    String name,
    List<Map<String, dynamic>> cards, {
    String? sprite1,
    String? sprite2,
  }) async {
    final response = await _api.post('/decks', {
      'name': name,
      'cards': cards,
      'sprite1': sprite1,
      'sprite2': sprite2,
    });
    return Deck.fromJson(response);
  }

  Future<Deck> updateDeck(String id, Map<String, dynamic> updates) async {
    final response = await _api.put('/decks/$id', updates);
    return Deck.fromJson(response);
  }

  Future<void> deleteDeck(String id) async {
    await _api.delete('/decks/$id');
  }
}