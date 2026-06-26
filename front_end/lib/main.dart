import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme_provider.dart';
import 'components/navbar.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/Appointments_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/onesignal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  final isLoggedIn = await AuthService.isLoggedIn();

  await OneSignalService.init();
  await NotificationService.init();

  final notifEnabled = prefs.getBool('notif_enabled') ?? true;
  if (notifEnabled) {
    await OneSignalService.requestPermission();
  }

  if (isLoggedIn) {
    await OneSignalService.sendPlayerIdToServer();

    final notifApp = prefs.getBool('notif_app') ?? true;
    if (notifEnabled && notifApp) {
      await NotificationService.startBadgePolling();
    }
  }

  runApp(MyApp(initialDarkMode: isDark, isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool initialDarkMode;
  final bool isLoggedIn;
  const MyApp({super.key, required this.initialDarkMode, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      initialDarkMode: initialDarkMode,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: isLoggedIn ? '/home' : '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/home': (_) => const MainScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _startBadgePolling();
    OneSignalService.setNotificationOpenedCallback(() {
      if (mounted) {
        setState(() => _selectedIndex = 2);
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _startBadgePolling() {
    _checkBadges();
    _badgeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkBadges());
  }

  Future<void> _checkBadges() async {
    try {
      await NotificationService.refreshPendingCount();
      await OneSignalService.updateBadgeCount(NotificationService.pendingCount);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    final hasPending = NotificationService.pendingCount > 0;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            OneSignalService.clearBadge();
          }
        },
        badges: [0, 0, hasPending ? NotificationService.pendingCount : 0, 0],
      ),
    );
  }
}
