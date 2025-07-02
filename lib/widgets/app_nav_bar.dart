// lib/widgets/app_nav_bar.dart
import 'package:flutter/material.dart';

/// A custom bottom navigation bar for the Mind Garden application.
class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Creates an instance of [AppNavBar].
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // The AppNavBar widget provides a bottom navigation bar with two items:
  // 1. Home (Entries)
  // 2. Stats
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          //label: 'Entries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          //label: 'Stats',
        ),
      ],
    );
  }
}