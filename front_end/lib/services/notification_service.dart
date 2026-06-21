import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _pollTimer;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  static Future<bool> _isAppNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_app') ?? true;
  }

  static Future<void> startPolling() async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkNewAppointments());
  }

  static void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static DateTime? _lastCheck;

  static Future<void> _checkNewAppointments() async {
    if (!await _isAppNotificationEnabled()) return;

    try {
      final response = await ApiService.get('/api/agendamentos/pendentes');
      final list = response['agendamentos'] ?? [];
      final now = DateTime.now();

      for (final item in (list as List)) {
        final createdAt = item['created_at'];
        if (createdAt == null) continue;
        final created = DateTime.parse(createdAt);
        if (_lastCheck != null && !created.isAfter(_lastCheck!)) continue;

        final clienteNome = item['cliente_nome'] ?? 'Cliente';
        final servico = item['servico'] ?? '';
        _showNotification('Novo agendamento', '$clienteNome agendou $servico');
      }

      _lastCheck = now;
    } catch (_) {}
  }

  static Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'agendamentos',
      'Agendamentos',
      channelDescription: 'Notificações de novos agendamentos',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(0, title, body, details);
  }

  static Future<void> showLocal(String title, String body) async {
    if (!await _isAppNotificationEnabled()) return;
    await _showNotification(title, body);
  }
}
