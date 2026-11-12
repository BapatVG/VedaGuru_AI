import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'rituals_screen.dart';
import 'wisdom_screen.dart';
import 'astrology_screen.dart';
import 'lifestyle_screen.dart';
import 'workspace_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const RitualsScreen(),
      const WisdomScreen(),
      const AstrologyScreen(),
      const LifestyleScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.3), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primarySaffron.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.surfaceElevated,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Text('🏠', style: TextStyle(fontSize: 18)),
              selectedIcon: const Text('🏡', style: TextStyle(fontSize: 22)),
              label: auth.tr('nav_daily'),
            ),
            NavigationDestination(
              icon: const Text('🕉️', style: TextStyle(fontSize: 18)),
              selectedIcon: const Text('🕉️', style: TextStyle(fontSize: 22)),
              label: auth.tr('nav_planner'),
            ),
            NavigationDestination(
              icon: const Text('📜', style: TextStyle(fontSize: 18)),
              selectedIcon: const Text('📜', style: TextStyle(fontSize: 22)),
              label: auth.tr('nav_wisdom'),
            ),
            NavigationDestination(
              icon: const Text('🪐', style: TextStyle(fontSize: 18)),
              selectedIcon: const Text('🪐', style: TextStyle(fontSize: 22)),
              label: auth.tr('nav_jyotish'),
            ),
            NavigationDestination(
              icon: const Text('🌿', style: TextStyle(fontSize: 18)),
              selectedIcon: const Text('🌿', style: TextStyle(fontSize: 22)),
              label: auth.tr('nav_lifestyle'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkspaceScreen()),
          );
        },
        backgroundColor: AppTheme.primarySaffron,
        tooltip: auth.tr('nav_workspace'),
        child: const Text('🏛️', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
