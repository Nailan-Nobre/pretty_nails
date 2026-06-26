// lib/components/navbar.dart
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<int> badges;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    this.badges = const [0, 0, 0, 0],
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
    final count = index < badges.length ? badges[index] : 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
