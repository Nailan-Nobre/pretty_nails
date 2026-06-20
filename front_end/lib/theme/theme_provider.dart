import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
export 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';
  bool _isDark;

  ThemeProvider({required bool initialDark}) : _isDark = initialDark;

  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeProvider>()!.data;
  }

  bool get isDark => _isDark;

  AppColors get colors => _isDark ? AppColors.dark : AppColors.light;

  ThemeData get lightTheme {
    final c = AppColors.light;
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.bgPrimary,
      cardColor: c.cardBg,
      colorScheme: ColorScheme.light(
        primary: c.primary,
        secondary: c.secondary,
        surface: c.bgPrimary,
        error: c.danger,
        onPrimary: c.textLight,
        onSecondary: c.textLight,
        onSurface: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgPrimary,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: c.textPrimary),
        bodyMedium: TextStyle(color: c.textPrimary),
        bodySmall: TextStyle(color: c.textSecondary),
      ),
      dividerColor: c.borderColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.disabledText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primaryLight;
          return c.disabledBg;
        }),
      ),
    );
  }

  ThemeData get darkTheme {
    final c = AppColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.bgPrimary,
      cardColor: c.cardBg,
      colorScheme: ColorScheme.dark(
        primary: c.primary,
        secondary: c.secondary,
        surface: c.bgSecondary,
        error: c.danger,
        onPrimary: c.textLight,
        onSecondary: c.textLight,
        onSurface: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgSecondary,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: c.textPrimary),
        bodyMedium: TextStyle(color: c.textPrimary),
        bodySmall: TextStyle(color: c.textSecondary),
      ),
      dividerColor: c.borderColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.disabledText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primaryLight;
          return c.disabledBg;
        }),
      ),
    );
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
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
  const ThemeScope({super.key, required this.child, this.initialDarkMode = false});

  @override
  State<ThemeScope> createState() => _ThemeScopeState();
}

class _ThemeScopeState extends State<ThemeScope> {
  late final ThemeProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ThemeProvider(initialDark: widget.initialDarkMode);
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
      child: MaterialApp(
        title: 'Pretty Nails',
        theme: _provider.lightTheme,
        darkTheme: _provider.darkTheme,
        themeMode: _provider.isDark ? ThemeMode.dark : ThemeMode.light,
        home: widget.child,
      ),
    );
  }
}
