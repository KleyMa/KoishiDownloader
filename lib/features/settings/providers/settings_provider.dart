import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final formatIndex = prefs.getInt(AppConstants.keyDefaultFormat) ?? 0;
    final videoQuality =
        prefs.getString(AppConstants.keyDefaultVideoQuality) ?? '720p';
    final audioQuality =
        prefs.getString(AppConstants.keyDefaultAudioQuality) ?? '320kbps';
    // Using absolute paths in the public Download directory so yt-dlp has write access on Android 10+
    const defaultBase = '/storage/emulated/0/Download/MusicDownloader';
    var videoPath = prefs.getString(AppConstants.keyVideoPath);
    var musicPath = prefs.getString(AppConstants.keyMusicPath);
    
    // Migrate old relative paths to absolute paths
    if (videoPath == null || !videoPath.startsWith('/')) {
      videoPath = '$defaultBase/Videos';
      prefs.setString(AppConstants.keyVideoPath, videoPath);
    }
    if (musicPath == null || !musicPath.startsWith('/')) {
      musicPath = '$defaultBase/Music';
      prefs.setString(AppConstants.keyMusicPath, musicPath);
    }
    
    final locale = prefs.getString(AppConstants.keyLocale) ?? 'en';
    final selectedPlatforms =
        prefs.getStringList(AppConstants.keySelectedPlatforms) ??
            ['YouTube', 'Facebook', 'Twitter/X'];

    state = AppSettings(
      defaultFormat: DownloadFormat.values[formatIndex],
      defaultVideoQuality: videoQuality,
      defaultAudioQuality: audioQuality,
      videoDownloadPath: videoPath,
      musicDownloadPath: musicPath,
      locale: locale,
      selectedPlatforms: selectedPlatforms,
    );
  }

  Future<void> updateFormat(DownloadFormat format) async {
    state = state.copyWith(defaultFormat: format);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyDefaultFormat, format.index);
  }

  Future<void> updateVideoQuality(String quality) async {
    state = state.copyWith(defaultVideoQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyDefaultVideoQuality, quality);
  }

  Future<void> updateAudioQuality(String quality) async {
    state = state.copyWith(defaultAudioQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyDefaultAudioQuality, quality);
  }

  Future<void> updateVideoPath(String path) async {
    state = state.copyWith(videoDownloadPath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyVideoPath, path);
  }

  Future<void> updateMusicPath(String path) async {
    state = state.copyWith(musicDownloadPath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMusicPath, path);
  }

  Future<void> updateLocale(String locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale);
  }

  Future<void> updateSelectedPlatforms(List<String> platforms) async {
    state = state.copyWith(selectedPlatforms: platforms);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keySelectedPlatforms, platforms);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final notifier = SettingsNotifier();
  notifier.loadSettings();
  return notifier;
});
