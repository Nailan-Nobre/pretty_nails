// lib/components/navbar.dart
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.bgPrimary,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textSecondary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Calendário',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Agendamentos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
