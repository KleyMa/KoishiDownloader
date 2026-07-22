import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../features/download/pages/download_page.dart';
import '../features/playlist/pages/playlist_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../core/utils/permissions_helper.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request permissions after the first frame is rendered
    // to avoid blocking the Flutter engine initialization in release mode.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await PermissionsHelper.requestAllPermissions();
      if (!granted && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF282828),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              tr('permissions_modal_title'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              tr('permissions_modal_desc'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  tr('i_understand'),
                  style: const TextStyle(
                    color: Color(0xFF1DB954),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

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
