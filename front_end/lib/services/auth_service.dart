import 'package:shared_preferences/shared_preferences.dart';
import '../models/manicure.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'onesignal_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (response['access_token'] != null) {
      await ApiService.setToken(response['access_token']);
    }
    if (response['refresh_token'] != null) {
      await ApiService.setRefreshToken(response['refresh_token']);
    }

    return response;
  }

  static Future<Map<String, dynamic>> signUp({
    required String nome,
    required String email,
    required String password,
    required String telefone,
    required String estado,
    required String cidade,
  }) async {
    return await ApiService.post('/auth/signup', body: {
      'nome': nome,
      'email': email,
      'password': password,
      'telefone': telefone,
      'estado': estado,
      'cidade': cidade,
      'tipo': 'MANICURE',
    });
  }

  static Future<Manicure> getProfile({bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadProfile();
      if (cached != null) return Manicure.fromJson(cached);
    }
    final response = await ApiService.get('/auth/profile');
    await CacheService.saveProfile(response['user']);
    return Manicure.fromJson(response['user']);
  }

  static Future<Manicure> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('/auth/profile', body: data);
    return Manicure.fromJson(response['user']);
  }

  static Future<String> uploadPhoto(String base64Image, {String? fotoAntiga}) async {
    final response = await ApiService.post('/auth/upload', body: {
      'image': base64Image,
      'fotoAntiga': fotoAntiga,
    });
    return response['url'];
  }

  static Future<Manicure?> getManicureBySlug(String slug) async {
    try {
      final response = await ApiService.get('/auth/manicure/$slug');
      return Manicure.fromJson(response['manicure']);
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refresh_token');
      await CacheService.clearAll();
      try {
        await OneSignalService.removeExternalUserId();
      } catch (_) {}
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  static Future<Map<String, dynamic>> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    return await ApiService.post('/auth/change-email', body: {
      'newEmail': newEmail,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiService.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> deleteAccount({
    required String password,
  }) async {
    final response = await ApiService.post('/auth/delete-account', body: {
      'password': password,
    });
    await logout();
    return response;
  }
}
