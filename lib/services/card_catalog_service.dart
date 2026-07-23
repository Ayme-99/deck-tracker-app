import '../models/card_suggestion.dart';
import 'api_service.dart';

class CardCatalogService {
  final _api = ApiService();

  Future<List<CardSuggestion>> search(String query) async {
    final response = await _api.get('/cards/search?q=${Uri.encodeQueryComponent(query)}');
    return (response as List).map((c) => CardSuggestion.fromJson(c)).toList();
  }
}
