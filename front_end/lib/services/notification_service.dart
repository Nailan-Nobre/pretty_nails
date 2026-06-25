import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _pollTimer;
  static int _notificationId = 0;
  static int _pendingCount = 0;

  static int get pendingCount => _pendingCount;

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
          'agendamentos',
          'Agendamentos',
          description: 'Notificações de novos agendamentos',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
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
    await _checkNewAppointments();
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
      final count = list.length;

      if (count != _pendingCount) {
        _pendingCount = count;
        _updateBadge(count);
      }

      for (final item in list) {
        final createdAt = item['created_at'];
        if (createdAt == null) continue;
        final created = DateTime.parse(createdAt);

        if (_lastCheck != null && !created.isAfter(_lastCheck!)) continue;

        final clienteNome = item['cliente_nome'] ?? 'Cliente';
        final servico = item['servico'] ?? '';
        await _showNotification('Novo agendamento', '$clienteNome agendou $servico');
      }

      _lastCheck = DateTime.now();
    } catch (_) {}
  }

  static Future<void> _updateBadge(int count) async {
    await _plugin.show(
      0,
      '',
      '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'agendamentos',
          'Agendamentos',
          channelDescription: 'Notificações de novos agendamentos',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
    await _plugin.cancel(0);
  }

  static Future<void> _showNotification(String title, String body) async {
    _notificationId++;

    final androidDetails = AndroidNotificationDetails(
      'agendamentos',
      'Agendamentos',
      channelDescription: 'Notificações de novos agendamentos',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(_notificationId, title, body, details);
  }

  static Future<void> showLocal(String title, String body) async {
    if (!await _isAppNotificationEnabled()) return;
    await _showNotification(title, body);
  }
}
