import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../features/download/pages/download_page.dart';
import '../features/playlist/pages/playlist_page.dart';
import '../features/settings/pages/settings_page.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DownloadPage(),
    PlaylistPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFF1DB954).withValues(alpha: 0.15),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.download_rounded, color: Color(0xFFB3B3B3)),
              selectedIcon: const Icon(Icons.download_rounded, color: Color(0xFF1DB954)),
              label: tr('download'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.playlist_play_rounded, color: Color(0xFFB3B3B3)),
              selectedIcon: const Icon(Icons.playlist_play_rounded, color: Color(0xFF1DB954)),
              label: tr('playlist'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_rounded, color: Color(0xFFB3B3B3)),
              selectedIcon: const Icon(Icons.settings_rounded, color: Color(0xFF1DB954)),
              label: tr('settings'),
            ),
          ],
        ),
      ),
    );
  }
}
