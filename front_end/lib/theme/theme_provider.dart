import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
export 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';
  static const _userSetKey = 'dark_mode_user_set';
  bool _isDark;
  bool _followSystem;

  ThemeProvider({required bool initialDark, bool followSystem = false})
      : _isDark = initialDark,
        _followSystem = followSystem;

  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeProvider>()!.data;
  }

  bool get isDark => _isDark;

  AppColors get colors => _isDark ? AppColors.dark : AppColors.light;

  /// Retorna true se o tema está seguindo o sistema (sem preferência manual)
  bool get isFollowingSystem => _followSystem;

  /// Cor para usar na tela de login/cadastro (sempre baseada no sistema)
  AppColors get systemColors {
    final systemDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    return systemDark ? AppColors.dark : AppColors.light;
  }

  Future<void> setDarkMode(bool value) async {
    _isDark = value;
    _followSystem = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
    await prefs.setBool(_userSetKey, true);
  }

  /// Volta a seguir o tema do sistema
  Future<void> followSystem() async {
    final systemDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    _isDark = systemDark;
    _followSystem = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
    await prefs.setBool(_userSetKey, false);
  }
}

class _ThemeProvider extends InheritedWidget {
  final ThemeProvider data;

  const _ThemeProvider({required this.data, required super.child});

  @override
  bool updateShouldNotify(_ThemeProvider oldWidget) => true;
}

class ThemeScope extends StatefulWidget {
  final Widget child;
  final bool initialDarkMode;
  final bool followSystem;
  const ThemeScope({super.key, required this.child, this.initialDarkMode = false, this.followSystem = false});

  @override
  State<ThemeScope> createState() => _ThemeScopeState();
}

class _ThemeScopeState extends State<ThemeScope> {
  late final ThemeProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ThemeProvider(initialDark: widget.initialDarkMode, followSystem: widget.followSystem);
    _provider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onThemeChanged);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeProvider(
      data: _provider,
      child: widget.child,
    );
  }
}
