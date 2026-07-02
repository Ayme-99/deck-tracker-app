import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register(String username, String password) async {
    final response = await _api.post('/auth/register', {
      'username': username,
      'password': password,
    });
    await _storage.write(key: 'token', value: response['token']);
    return response;
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
  }
}