import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

class DownloadState {
  final String currentUrl;
  final String selectedPlatform;
  final DownloadFormat selectedFormat;
  final String selectedQuality;
  final bool isPlaylistMode;
  final bool isLoading;

  const DownloadState({
    this.currentUrl = '',
    this.selectedPlatform = 'YouTube',
    this.selectedFormat = DownloadFormat.mp3,
    this.selectedQuality = '320kbps',
    this.isPlaylistMode = false,
    this.isLoading = false,
  });

  DownloadState copyWith({
    String? currentUrl,
    String? selectedPlatform,
    DownloadFormat? selectedFormat,
    String? selectedQuality,
    bool? isPlaylistMode,
    bool? isLoading,
  }) {
    return DownloadState(
      currentUrl: currentUrl ?? this.currentUrl,
      selectedPlatform: selectedPlatform ?? this.selectedPlatform,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      isPlaylistMode: isPlaylistMode ?? this.isPlaylistMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier() : super(const DownloadState());

  void setUrl(String url) {
    final platform = _detectPlatform(url);
    state = state.copyWith(
      currentUrl: url,
      selectedPlatform: platform,
    );
  }

  void setPlatform(String platform) {
    state = state.copyWith(selectedPlatform: platform);
  }

  void setFormat(DownloadFormat format) {
    final quality = format == DownloadFormat.mp3 ? '320kbps' : '720p';
    state = state.copyWith(
      selectedFormat: format,
      selectedQuality: quality,
    );
  }

  void setQuality(String quality) {
    state = state.copyWith(selectedQuality: quality);
  }

  void togglePlaylistMode() {
    state = state.copyWith(isPlaylistMode: !state.isPlaylistMode);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void resetForm() {
    state = state.copyWith(
      currentUrl: '',
      isPlaylistMode: false,
      isLoading: false,
    );
  }

  String _detectPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'YouTube';
    } else if (lower.contains('facebook.com') || lower.contains('fb.watch')) {
      return 'Facebook';
    } else if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return 'Twitter/X';
    } else if (lower.contains('instagram.com')) {
      return 'Instagram';
    } else if (lower.contains('tiktok.com')) {
      return 'TikTok';
    }
    return 'Other';
  }
}

final downloadFormProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  return DownloadNotifier();
});
