import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/platform_channel.dart';
import 'core/utils/permissions_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF181818),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize notification service
  try {
    final notificationService = NotificationService.instance;
    await notificationService.init();
    debugPrint('[main] Notifications initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('[main] Notification initialization failed: $e');
    debugPrint('[main] Stack trace:\n$stackTrace');
  }

  // (Permissions are now requested in AppRouter to avoid blocking release builds)

  // Initialize yt-dlp (pre-warm; will auto-retry on first download if it fails)
  try {
    await YtDlpService().ensureInitialized();
    debugPrint('[main] yt-dlp initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('[main] yt-dlp initialization failed: $e');
    debugPrint('[main] Stack trace:\n$stackTrace');
    // App can still start; yt-dlp will auto-initialize on first download
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/l10n',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}
