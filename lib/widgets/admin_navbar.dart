import 'package:flutter/material.dart';
import '../theme_sync.dart';

class AdminNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.onPrimary,
        unselectedItemColor: theme.colorScheme.onPrimary.withOpacity(0.6),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Facturas',
          ),
        ],
      ),
    );
  }
}
