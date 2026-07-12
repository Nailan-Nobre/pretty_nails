import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static Timer? _pollTimer;
  static int _pendingCount = 0;

  static int get pendingCount => _pendingCount;

  static Future<void> init() async {}

  static Future<void> startBadgePolling() async {
    _pollTimer?.cancel();
    await _checkBadges();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkBadges());
  }

  static void stopBadgePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static Future<void> refreshPendingCount() async {
    await _checkBadges();
  }

  static Future<void> _checkBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final notifApp = prefs.getBool('notif_app') ?? true;
    if (!notifApp) return;

    try {
      final response = await ApiService.get('/api/agendamentos/pendentes');
      final list = response['agendamentos'] ?? [];
      _pendingCount = list.length;
    } catch (_) {}
  }
}
