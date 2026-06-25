import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OneSignalService {
  static const String _appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'c165041f-74ec-4790-b66e-aaaa78601453',
  );

  static Future<void> init() async {
    if (_appId.isEmpty) return;

    OneSignal.initialize(_appId);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      event.notification.display();
    });
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
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId == null || playerId.isEmpty) return;

    try {
      await ApiService.post('/auth/player-id', body: {
        'player_id': playerId,
      });
    } catch (_) {}
  }

  static Future<bool> requestPermission() async {
    if (_appId.isEmpty) return false;
    final result = await OneSignal.Notifications.requestPermission(false);
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
}
