import 'package:flutter/material.dart';
import 'theme_provider.dart';

extension BuildContextTheme on BuildContext {
  AppColors get colors => ThemeProvider.of(this).colors;
  ThemeProvider get themeProvider => ThemeProvider.of(this);
}
