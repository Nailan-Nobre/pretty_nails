import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://pretty-nails-do11.vercel.app',
  );

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> setRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['access_token'] != null) {
          await setToken(body['access_token']);
          if (body['refresh_token'] != null) {
            await setRefreshToken(body['refresh_token']);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final headers = await _headers();
    var response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _headers();
        response = await http.get(
          Uri.parse('$baseUrl$path'),
          headers: newHeaders,
        );
      }
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    var response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401 && path != '/auth/refresh') {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _headers();
        response = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: newHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    var response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _headers();
        response = await http.put(
          Uri.parse('$baseUrl$path'),
          headers: newHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    var response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _headers();
        response = await http.patch(
          Uri.parse('$baseUrl$path'),
          headers: newHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] ?? body['message'] ?? 'Erro desconhecido',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
