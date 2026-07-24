import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';

/// Snapshot cacheado del listado de mazos + sus overviews (issue #133):
/// lo que necesita DeckListScreen para pintar la pantalla principal sin red.
class DeckListSnapshot {
  final List<Deck> decks;
  final Map<String, Map<String, dynamic>> overviews;

  DeckListSnapshot({required this.decks, required this.overviews});
}

/// Cache local (shared_preferences, JSON) del listado de mazos y sus
/// overviews, para poder mostrar algo instantaneo mientras se refresca en
/// segundo plano, o si no hay red en absoluto (issue #133). Alcance
/// deliberadamente reducido a la pantalla principal (mazos); torneos queda
/// fuera por ahora, ver discusion en el issue.
///
/// Estrategia "write-through": cada carga de red que tiene exito sobreescribe
/// el snapshot guardado. No hay invalidacion por tiempo -- el propio flujo de
/// DeckListScreen siempre intenta refrescar desde red al abrir la pantalla,
/// asi que el cache solo se usa como "algo que mostrar mientras tanto" o como
/// ultimo recurso si esa red falla.
class DeckCacheService {
  static const _key = 'cache_deck_list_snapshot_v1';

  Future<void> save(List<Deck> decks, Map<String, Map<String, dynamic>> overviews) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'decks': decks.map((d) => d.toJson()).toList(),
      'overviews': overviews,
    });
    await prefs.setString(_key, payload);
  }

  /// Devuelve null si no hay nada guardado o si el JSON esta corrupto (ej.
  /// cambio de formato entre versiones de la app).
  Future<DeckListSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final decks = (decoded['decks'] as List)
          .map((d) => Deck.fromJson(d as Map<String, dynamic>))
          .toList();
      final overviews = (decoded['overviews'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as Map<String, dynamic>));

      return DeckListSnapshot(decks: decks, overviews: overviews);
    } catch (_) {
      return null;
    }
  }
}
