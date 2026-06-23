import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _prefix = 'cache_';
  static const _profileKey = '${_prefix}profile';
  static const _feedbacksKey = '${_prefix}feedbacks_';
  static const _estatisticasKey = '${_prefix}estatisticas';
  static const _pendentesKey = '${_prefix}pendentes';
  static const _confirmadosKey = '${_prefix}confirmados';
  static const _historicoKey = '${_prefix}historico';
  static const _meusAgendamentosKey = '${_prefix}meus_agendamentos';

  static Future<void> saveProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_profileKey);
    if (str == null) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }

  static Future<void> saveFeedbacks(String manicureId, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_feedbacksKey$manicureId', jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadFeedbacks(String manicureId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$_feedbacksKey$manicureId');
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveEstatisticas(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_estatisticasKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadEstatisticas() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_estatisticasKey);
    if (str == null) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }

  static Future<void> savePendentes(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendentesKey, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadPendentes() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_pendentesKey);
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveConfirmados(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_confirmadosKey, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadConfirmados() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_confirmadosKey);
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveHistorico(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historicoKey, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_historicoKey);
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveMeusAgendamentos(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_meusAgendamentosKey, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadMeusAgendamentos() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_meusAgendamentosKey);
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
