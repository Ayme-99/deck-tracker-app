import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'deck_cache_service.dart';

class AuthService {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  final _deckCacheService = DeckCacheService();

  Future<Map<String, dynamic>> register(String username, String password, String email) async {
    final response = await _api.post('/auth/register', {
      'username': username,
      'password': password,
      'email': email,
    });
    await _storage.write(key: 'token', value: response['token']);
    return response;
  }

  Future<Map<String, dynamic>> resendVerificationEmail() async {
    return await _api.post('/auth/resend-verification', {});
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _api.post('/auth/login', {
      'username': username,
      'password': password,
    });
    await _storage.write(key: 'token', value: response['token']);
    return response;
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _api.get('/auth/me');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    // Issue #234: sin esto, al iniciar sesion con otra cuenta se veian
    // brevemente los mazos del usuario anterior (el cache local no
    // distingue de quien es, y DeckListScreen lo muestra al instante
    // mientras espera la respuesta de red).
    await _deckCacheService.clear();
  }
}