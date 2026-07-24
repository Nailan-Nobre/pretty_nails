import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const _prefix = 'tutorial_step_';
  static const _scheduleKey = 'schedule_tutorial_seen';

  static Future<bool> hasCompletedStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$step') ?? false;
  }

  static Future<void> markStepCompleted(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$step', true);
  }

  static Future<bool> hasSeenScheduleTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_scheduleKey) ?? false;
  }

  static Future<void> markScheduleTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scheduleKey, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i <= 4; i++) {
      await prefs.remove('$_prefix$i');
    }
    await prefs.remove(_scheduleKey);
  }
}
