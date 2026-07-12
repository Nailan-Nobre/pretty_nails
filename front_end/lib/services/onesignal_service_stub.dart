import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static Future<void> init() async {}

  static Future<void> updateBadgeCount(int count) async {
    _unreadCount = count;
  }

  static Future<void> clearBadge() async {
    _unreadCount = 0;
  }

  static Future<void> setExternalUserId(String userId) async {}

  static Future<void> removeExternalUserId() async {}

  static Future<void> sendPlayerIdToServer() async {}

  static Future<bool> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onesignal_permission', true);
    return true;
  }

  static bool isPermissionGranted() => false;

  static Future<void> optIn() async {}

  static Future<void> optOut() async {}

  static Future<void> revokePermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onesignal_permission', false);
  }
}
