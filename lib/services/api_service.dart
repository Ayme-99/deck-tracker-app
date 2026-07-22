import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/navigation_service.dart';
import '../screens/auth/login_screen.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  // Static porque cada service crea su propia instancia de ApiService:
  // el guard debe compartirse entre todas para no apilar Logins con 401 simultáneos.
  static bool _redirectingToLogin = false;

  /// Devuelve los headers y si la petición lleva token.
  /// [hadToken] permite distinguir un 401 por sesión caducada (llevaba token)
  /// de un 401 por petición zombi lanzada tras el logout (sin token).
  Future<({Map<String, String> headers, bool hadToken})> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return (
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      hadToken: token != null,
    );
  }

  Future<dynamic> get(String endpoint) async {
    final auth = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: auth.headers,
    );
    return _handleResponse(response, hadToken: auth.hadToken);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final auth = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: auth.headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, hadToken: auth.hadToken);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final auth = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: auth.headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, hadToken: auth.hadToken);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final auth = await _getHeaders();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: auth.headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, hadToken: auth.hadToken);
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final auth = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: auth.headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, hadToken: auth.hadToken);
  }

  Future<dynamic> _handleResponse(http.Response response, {required bool hadToken}) async {
    // El body puede no ser JSON (p. ej. HTML de un 502 del proxy de Render durante el cold start)
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Solo tratamos el 401 como sesión caducada si la petición llevaba token.
    // Un 401 sin token es una petición zombi (lanzada antes del logout, resuelta después):
    // no debe borrar el token actual ni navegar.
    if (response.statusCode == 401 && hadToken) {
      await _handleSessionExpired();
    }

    final errorMessage = (data is Map && data['error'] != null)
        ? data['error']
        : 'Error en la petición (${response.statusCode})';
    throw Exception(errorMessage);
  }

  Future<void> _handleSessionExpired() async {
    await _storage.delete(key: 'token');

    // Evita navegar varias veces si llegan varios 401 casi a la vez
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    // Libera el guard pasado un margen, por si en el futuro hay una caducidad real tras re-login
    Future.delayed(const Duration(seconds: 2), () => _redirectingToLogin = false);
  }
}