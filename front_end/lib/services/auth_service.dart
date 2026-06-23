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

    await OneSignalService.requestPermission();
    await OneSignalService.sendPlayerIdToServer();

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await CacheService.clearAll();
    await OneSignalService.removeExternalUserId();
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }
}
