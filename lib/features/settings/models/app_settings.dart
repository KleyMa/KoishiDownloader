import 'package:koishi_downloader/core/constants/app_constants.dart';

/// Immutable model that represents the user's persisted preferences.
///
/// Stored / loaded via SharedPreferences using [toJson] / [fromJson].
class AppSettings {
  const AppSettings({
    this.defaultFormat = DownloadFormat.mp3,
    this.defaultVideoQuality = '720p',
    this.defaultAudioQuality = '320kbps',
    this.videoDownloadPath = '',
    this.musicDownloadPath = '',
    this.locale = 'en',
    this.selectedPlatforms = const ['YouTube', 'Facebook', 'Twitter/X'],
  });

  /// Preferred output format for new downloads.
  final DownloadFormat defaultFormat;

  /// Preferred video quality label (e.g. `720p`).
  final String defaultVideoQuality;

  /// Preferred audio quality label (e.g. `320kbps`).
  final String defaultAudioQuality;

  /// Absolute directory path for saving video downloads.
  ///
  /// Empty string means the path has not been configured yet (first launch).
  final String videoDownloadPath;

  /// Absolute directory path for saving music downloads.
  ///
  /// Empty string means the path has not been configured yet (first launch).
  final String musicDownloadPath;

  /// Current locale code (`en` or `es`).
  final String locale;

  /// User selected platforms to display (max 3).
  final List<String> selectedPlatforms;

  /// Whether the download paths have been configured.
  bool get isPathsConfigured =>
      videoDownloadPath.isNotEmpty && musicDownloadPath.isNotEmpty;

  // ──────────────────────────────────────────────────────────────────────────
  //  copyWith
  // ──────────────────────────────────────────────────────────────────────────

  AppSettings copyWith({
    DownloadFormat? defaultFormat,
    String? defaultVideoQuality,
    String? defaultAudioQuality,
    String? videoDownloadPath,
    String? musicDownloadPath,
    String? locale,
    List<String>? selectedPlatforms,
  }) {
    return AppSettings(
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      defaultAudioQuality: defaultAudioQuality ?? this.defaultAudioQuality,
      videoDownloadPath: videoDownloadPath ?? this.videoDownloadPath,
      musicDownloadPath: musicDownloadPath ?? this.musicDownloadPath,
      locale: locale ?? this.locale,
      selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  JSON serialisation (for SharedPreferences)
  // ──────────────────────────────────────────────────────────────────────────

  /// Serialises the settings to a flat map suitable for SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDefaultFormat: defaultFormat.name,
      AppConstants.keyDefaultVideoQuality: defaultVideoQuality,
      AppConstants.keyDefaultAudioQuality: defaultAudioQuality,
      AppConstants.keyVideoPath: videoDownloadPath,
      AppConstants.keyMusicPath: musicDownloadPath,
      AppConstants.keyLocale: locale,
      AppConstants.keySelectedPlatforms: selectedPlatforms,
    };
  }

  /// Creates an [AppSettings] from a map previously produced by [toJson], or
  /// from values read individually from SharedPreferences.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultFormat: DownloadFormat.fromString(
        json[AppConstants.keyDefaultFormat] as String? ?? 'mp3',
      ),
      defaultVideoQuality:
          json[AppConstants.keyDefaultVideoQuality] as String? ?? '720p',
      defaultAudioQuality:
          json[AppConstants.keyDefaultAudioQuality] as String? ?? '320kbps',
      videoDownloadPath:
          json[AppConstants.keyVideoPath] as String? ?? '',
      musicDownloadPath:
          json[AppConstants.keyMusicPath] as String? ?? '',
      locale: json[AppConstants.keyLocale] as String? ?? 'en',
      selectedPlatforms:
          (json[AppConstants.keySelectedPlatforms] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['YouTube', 'Facebook', 'Twitter/X'],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Equality & hashCode
  // ──────────────────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.defaultFormat == defaultFormat &&
        other.defaultVideoQuality == defaultVideoQuality &&
        other.defaultAudioQuality == defaultAudioQuality &&
        other.videoDownloadPath == videoDownloadPath &&
        other.musicDownloadPath == musicDownloadPath &&
        other.locale == locale &&
        _listEquals(other.selectedPlatforms, selectedPlatforms);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        defaultFormat,
        defaultVideoQuality,
        defaultAudioQuality,
        videoDownloadPath,
        musicDownloadPath,
        locale,
        Object.hashAll(selectedPlatforms),
      );

  @override
  String toString() =>
      'AppSettings(format: ${defaultFormat.name}, '
      'videoQuality: $defaultVideoQuality, '
      'audioQuality: $defaultAudioQuality, '
      'locale: $locale, '
      'selectedPlatforms: $selectedPlatforms)';
}
