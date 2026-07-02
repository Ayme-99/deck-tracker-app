import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/navigation_service.dart';
import '../screens/login_screen.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      await _handleSessionExpired();
    }

    throw Exception(data['error'] ?? 'Error en la petición (${response.statusCode})');
  }

  Future<void> _handleSessionExpired() async {
    await _storage.delete(key: 'token');

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    // Evita navegar si ya estamos en Login (por ejemplo, tras un intento fallido normal)
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}