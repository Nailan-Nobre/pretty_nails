import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badge/flutter_app_badge.dart';
import 'api_service.dart';

class OneSignalService {
  static const String _appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'c165041f-74ec-4790-b66e-aaaa78601453',
  );

  static int _unreadCount = 0;
  static int get unreadCount => _unreadCount;

  static VoidCallback? _onNotificationOpened;

  static void setNotificationOpenedCallback(VoidCallback callback) {
    _onNotificationOpened = callback;
  }

  static Future<void> init() async {
    if (_appId.isEmpty) return;

    OneSignal.initialize(_appId);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      _unreadCount++;
      _updateBadge();
      event.notification.display();
    });

    OneSignal.Notifications.addPermissionObserver((granted) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onesignal_permission', granted);
    });

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['type'] == 'novo_agendamento') {
        _onNotificationOpened?.call();
      }
    });
  }

  static Future<void> updateBadgeCount(int count) async {
    _unreadCount = count;
    await _updateBadge();
  }

  static Future<void> clearBadge() async {
    _unreadCount = 0;
    await _updateBadge();
  }

  static Future<void> _updateBadge() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      try {
        await FlutterAppBadge.count(_unreadCount);
      } catch (_) {}
    }
  }

  static Future<void> setExternalUserId(String userId) async {
    if (_appId.isEmpty) return;
    await OneSignal.login(userId);
  }

  static Future<void> removeExternalUserId() async {
    if (_appId.isEmpty) return;
    await OneSignal.logout();
  }

  static Future<void> sendPlayerIdToServer() async {
    if (_appId.isEmpty) return;

    for (var attempt = 0; attempt < 5; attempt++) {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null && playerId.isNotEmpty) {
        try {
          await ApiService.post('/auth/player-id', body: {
            'player_id': playerId,
          });
          return;
        } catch (_) {}
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Future<bool> requestPermission() async {
    if (_appId.isEmpty) return false;
    final result = await OneSignal.Notifications.requestPermission(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onesignal_permission', result);
    return result;
  }

  static bool isPermissionGranted() {
    if (_appId.isEmpty) return false;
    return OneSignal.User.pushSubscription.id != null;
  }

  static Future<void> optIn() async {
    if (_appId.isEmpty) return;
    OneSignal.User.pushSubscription.optIn();
  }

  static Future<void> optOut() async {
    if (_appId.isEmpty) return;
    OneSignal.User.pushSubscription.optOut();
  }

  static Future<void> revokePermission() async {
    if (_appId.isEmpty) return;
    OneSignal.User.pushSubscription.optOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onesignal_permission', false);
    if (!kIsWeb && Platform.isIOS) {
      try {
        await FlutterAppBadge.count(0);
      } catch (_) {}
    }
  }
}
