import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _pollTimer;
  static int _pendingCount = 0;

  static int get pendingCount => _pendingCount;

  static const String channelId = 'agendamentos';
  static const String channelName = 'Agendamentos';
  static const String channelDesc = 'Notificações de novos agendamentos';

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings, onDidReceiveNotificationResponse: (details) {});

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  }

  static Future<bool> _isAppNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_app') ?? true;
  }

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
    if (!await _isAppNotificationEnabled()) return;

    try {
      final response = await ApiService.get('/api/agendamentos/pendentes');
      final list = response['agendamentos'] ?? [];
      _pendingCount = list.length;
    } catch (_) {}
  }
}
