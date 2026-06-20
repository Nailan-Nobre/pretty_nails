import 'package:flutter/material.dart';

class AppColors {
  // Cores Primárias
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;

  // Cores Neutras
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textLight;

  // Cores de Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Cores de Borda
  final Color borderColor;
  final Color borderLight;

  // Sombras
  final Color shadowSm;
  final Color shadowMd;
  final Color shadowLg;

  // Cores de Interação
  final Color hoverBg;
  final Color activeBg;
  final Color focusRing;

  // Cores de Fundo de Componentes
  final Color cardBg;
  final Color inputBg;
  final Color inputBorder;
  final Color disabledBg;
  final Color disabledText;

  const AppColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLight,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.borderColor,
    required this.borderLight,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.hoverBg,
    required this.activeBg,
    required this.focusRing,
    required this.cardBg,
    required this.inputBg,
    required this.inputBorder,
    required this.disabledBg,
    required this.disabledText,
  });

  static const light = AppColors(
    primary: Color(0xFFFF6B6B),
    primaryLight: Color(0xFFFF8E8E),
    primaryDark: Color(0xFFE05555),
    secondary: Color(0xFF4ECDC4),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7FFF7),
    bgTertiary: Color(0xFFF1F3F5),
    textPrimary: Color(0xFF292F36),
    textSecondary: Color(0xFF6C757D),
    textLight: Color(0xFFFFFFFF),
    success: Color(0xFF28A745),
    warning: Color(0xFFFFC107),
    danger: Color(0xFFDC3545),
    info: Color(0xFF17A2B8),
    borderColor: Color(0xFFE9ECEF),
    borderLight: Color(0xFFF1F3F5),
    shadowSm: Color(0x1E000000),
    shadowMd: Color(0x1A000000),
    shadowLg: Color(0x1A000000),
    hoverBg: Color(0x1AFF6B6B),
    activeBg: Color(0x33FF6B6B),
    focusRing: Color(0x66FF6B6B),
    cardBg: Color(0xFFFFFFFF),
    inputBg: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFDEE2E6),
    disabledBg: Color(0xFFE9ECEF),
    disabledText: Color(0xFF6C757D),
  );

  static const dark = AppColors(
    primary: Color(0xFFFF6B6B),
    primaryLight: Color(0xFFFF8E8E),
    primaryDark: Color(0xFFE05555),
    secondary: Color(0xFF4ECDC4),
    bgPrimary: Color(0xFF2A2420),    
    bgSecondary: Color(0xFF332C28),  
    bgTertiary: Color(0xFF3D3530),   
    textPrimary: Color(0xFFF5EDE6),  
    textSecondary: Color(0xFFC4B5A6),
    textLight: Color(0xFFF5EDE6),
    success: Color(0xFF6FCF97),
    warning: Color(0xFFF2C94C),
    danger: Color(0xFFEB5757),
    info: Color(0xFF5DADE2),
    borderColor: Color(0xFF4A403A),
    borderLight: Color(0xFF3D3530),
    shadowSm: Color(0x99000000),
    shadowMd: Color(0x80000000),
    shadowLg: Color(0x99000000),
    hoverBg: Color(0x26FF6B6B),
    activeBg: Color(0x40FF6B6B),
    focusRing: Color(0x80FF6B6B),
    cardBg: Color(0xFF332C28),
    inputBg: Color(0xFF3D3530),
    inputBorder: Color(0xFF5A4E46),
    disabledBg: Color(0xFF3D3530),
    disabledText: Color(0xFF8A7A6C),
  );
}
