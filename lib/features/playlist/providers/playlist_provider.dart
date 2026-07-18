import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../download/providers/queue_provider.dart';

class PlaylistVideoItem {
  final String id;
  final String title;
  final String? thumbnail;
  final String? duration;
  final bool isSelected;

  const PlaylistVideoItem({
    required this.id,
    required this.title,
    this.thumbnail,
    this.duration,
    this.isSelected = true,
  });

  PlaylistVideoItem copyWith({
    String? id,
    String? title,
    String? thumbnail,
    String? duration,
    bool? isSelected,
  }) {
    return PlaylistVideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class PlaylistState {
  final bool isLoading;
  final String? playlistTitle;
  final List<PlaylistVideoItem> videos;
  final String? error;

  const PlaylistState({
    this.isLoading = false,
    this.playlistTitle,
    this.videos = const [],
    this.error,
  });

  PlaylistState copyWith({
    bool? isLoading,
    String? playlistTitle,
    List<PlaylistVideoItem>? videos,
    String? error,
  }) {
    return PlaylistState(
      isLoading: isLoading ?? this.isLoading,
      playlistTitle: playlistTitle ?? this.playlistTitle,
      videos: videos ?? this.videos,
      error: error,
    );
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final Ref _ref;

  PlaylistNotifier(this._ref) : super(const PlaylistState());

  Future<void> fetchPlaylist(String url) async {
    state = state.copyWith(isLoading: true, error: null, videos: []);

    try {
      final ytDlp = _ref.read(ytDlpServiceProvider);
      final results = await ytDlp.getPlaylistInfo(url);

      final videos = results.map((data) {
        final id = data['id'] as String? ?? '';
        final title = data['title'] as String? ?? 'Unknown';
        final thumbnail = data['thumbnail'] as String?;
        final durationSecs = data['duration'] as num?;
        String? durationStr;
        if (durationSecs != null) {
          final mins = durationSecs.toInt() ~/ 60;
          final secs = durationSecs.toInt() % 60;
          durationStr = '$mins:${secs.toString().padLeft(2, '0')}';
        }

        return PlaylistVideoItem(
          id: id,
          title: title,
          thumbnail: thumbnail,
          duration: durationStr,
          isSelected: true,
        );
      }).toList();

      final playlistTitle = results.isNotEmpty
          ? (results.first['playlist_title'] as String? ?? 'Playlist')
          : 'Playlist';

      state = state.copyWith(
        isLoading: false,
        playlistTitle: playlistTitle,
        videos: videos,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void toggleVideoSelection(String id) {
    state = state.copyWith(
      videos: [
        for (final video in state.videos)
          if (video.id == id)
            video.copyWith(isSelected: !video.isSelected)
          else
            video,
      ],
    );
  }

  void selectAll() {
    state = state.copyWith(
      videos: state.videos.map((v) => v.copyWith(isSelected: true)).toList(),
    );
  }

  void deselectAll() {
    state = state.copyWith(
      videos: state.videos.map((v) => v.copyWith(isSelected: false)).toList(),
    );
  }

  List<PlaylistVideoItem> getSelectedVideos() {
    return state.videos.where((v) => v.isSelected).toList();
  }

  void reset() {
    state = const PlaylistState();
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  return PlaylistNotifier(ref);
});
