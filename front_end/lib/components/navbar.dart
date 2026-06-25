// lib/components/navbar.dart
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<bool> badges;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    this.badges = const [false, false, false, false],
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
      items: [
        BottomNavigationBarItem(
          icon: _buildBadgeIcon(Icons.home, 0),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgeIcon(Icons.calendar_month, 1),
          label: 'Calendário',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgeIcon(Icons.event, 2),
          label: 'Agendamentos',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgeIcon(Icons.person, 3),
          label: 'Perfil',
        ),
      ],
    );
  }

  Widget _buildBadgeIcon(IconData icon, int index) {
    final showBadge = index < badges.length && badges[index];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
