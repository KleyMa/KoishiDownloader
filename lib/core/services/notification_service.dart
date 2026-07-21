import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages local notifications for download progress, completion, and errors.
///
/// Uses two Android notification channels:
/// * **downloads_progress** – low importance (silent) for ongoing progress bars.
/// * **downloads_alerts** – high importance for completed / error alerts.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Channel IDs ─────────────────────────────────────────────────────────
  static const String _progressChannelId = 'downloads_progress';
  static const String _progressChannelName = 'Download Progress';
  static const String _progressChannelDesc =
      'Shows ongoing download progress silently';

  static const String _alertChannelId = 'downloads_alerts';
  static const String _alertChannelName = 'Downloads';
  static const String _alertChannelDesc =
      'Alerts when a download completes or fails';

  // ──────────────────────────────────────────────────────────────────────────
  //  Initialisation
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialise the notification plugin.
  ///
  /// Safe to call multiple times – subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialised) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Pre-create the notification channels so Android registers them
    // immediately.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _progressChannelId,
          _progressChannelName,
          description: _progressChannelDesc,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertChannelId,
          _alertChannelName,
          description: _alertChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialised = true;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Progress notification
  // ──────────────────────────────────────────────────────────────────────────

  /// Shows or updates a download-progress notification.
  ///
  /// * [id]       – Unique notification ID (use per-download).
  /// * [title]    – e.g. the video title.
  /// * [progress] – Integer 0 – 100.
  Future<void> showProgressNotification(
    int id,
    String title,
    String body,
    int progress,
  ) async {
    final clampedProgress = progress.clamp(0, 100);

    final androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: clampedProgress,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
      subText: '$clampedProgress%',
      category: AndroidNotificationCategory.progress,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Completed notification
  // ──────────────────────────────────────────────────────────────────────────

  /// Shows a "download complete" notification.
  Future<void> showCompletedNotification(int id, String title) async {
    const androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.status,
    );

    await _plugin.show(
      id,
      title,
      'Download completed',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Error notification
  // ──────────────────────────────────────────────────────────────────────────

  /// Shows an error notification for a failed download.
  Future<void> showErrorNotification(
    int id,
    String title,
    String error,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.error,
    );

    await _plugin.show(
      id,
      title,
      'Error: $error',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Cancel helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Cancel a single notification by [id].
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all active notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Private
  // ──────────────────────────────────────────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    // Intentionally left as a hook for future deep-link / navigation logic.
    // The payload (response.payload) can carry the download ID so the UI
    // can scroll to the relevant item.
  }
}
