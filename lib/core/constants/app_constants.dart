import 'package:flutter/material.dart';

/// Centralised application constants.
class AppConstants {
  AppConstants._();

  // ── Platform Channel names ──────────────────────────────────────────────
  static const String ytdlpChannel = 'com.example.music_downloader/ytdlp';
  static const String progressChannel =
      'com.example.music_downloader/download_progress';

  // ── Video qualities ─────────────────────────────────────────────────────
  static const List<String> videoQualities = [
    '360p',
    '480p',
    '720p',
    '1080p',
    '1440p',
    '2160p',
  ];

  // ── Audio qualities ─────────────────────────────────────────────────────
  static const List<String> audioQualities = [
    '128kbps',
    '192kbps',
    '256kbps',
    '320kbps',
  ];

  /// Maps the display label to the numeric value yt-dlp expects.
  static const Map<String, String> audioQualityMap = {
    '128kbps': '128',
    '192kbps': '192',
    '256kbps': '256',
    '320kbps': '320',
  };

  // ── Supported platforms ─────────────────────────────────────────────────
  static const List<String> platforms = [
    'YouTube',
    'Facebook',
    'Twitter/X',
    'Instagram',
    'TikTok',
    'Other',
  ];

  /// Maps platform names to Material Icons.
  static const Map<String, IconData> platformIcons = {
    'YouTube': Icons.play_circle_fill,
    'Facebook': Icons.facebook,
    'Twitter/X': Icons.alternate_email,
    'Instagram': Icons.camera_alt,
    'TikTok': Icons.music_note,
    'Other': Icons.language,
  };

  // ── Default paths ───────────────────────────────────────────────────────
  static const String defaultMusicFolder = 'KoishiDownloader/Music';
  static const String defaultVideoFolder = 'KoishiDownloader/Videos';

  // ── SharedPreferences keys ──────────────────────────────────────────────
  static const String keyDefaultFormat = 'default_format';
  static const String keyDefaultVideoQuality = 'default_video_quality';
  static const String keyDefaultAudioQuality = 'default_audio_quality';
  static const String keyVideoPath = 'video_download_path';
  static const String keyMusicPath = 'music_download_path';
  static const String keyLocale = 'locale';
  static const String keyFirstLaunch = 'first_launch';
  static const String keySelectedPlatforms = 'selected_platforms';
}

/// The two output formats the app supports.
enum DownloadFormat {
  mp3,
  mp4;

  /// User-facing label.
  String get label => name.toUpperCase();

  /// Resolve from a stored string (case-insensitive).
  static DownloadFormat fromString(String value) {
    return DownloadFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DownloadFormat.mp3,
    );
  }
}

/// Lifecycle states of a single download task.
enum DownloadStatus {
  queued,
  fetchingInfo,
  downloading,
  converting,
  completed,
  error,
  cancelled,
  paused;

  /// Whether the task is still in progress (not terminal).
  bool get isActive =>
      this == queued ||
      this == fetchingInfo ||
      this == downloading ||
      this == converting;

  /// Whether the task reached a final state.
  bool get isTerminal =>
      this == completed || this == error || this == cancelled;

  /// Resolve from a stored string (case-insensitive).
  static DownloadStatus fromString(String value) {
    return DownloadStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DownloadStatus.queued,
    );
  }
}
