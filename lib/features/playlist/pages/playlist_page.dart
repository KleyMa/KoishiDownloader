import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../download/models/download_item.dart';
import '../../download/providers/queue_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/playlist_video_tile.dart';

class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({super.key});

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  final _urlController = TextEditingController();
  DownloadFormat _selectedFormat = DownloadFormat.mp3;
  String _selectedQuality = '320kbps';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF121212),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.playlist_play_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  tr('playlist'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1DB954).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // URL Input
                Card(
                  color: const Color(0xFF282828),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: tr('playlist_url_hint'),
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF181818),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.playlist_play_rounded,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _FetchButton(
                            isLoading: playlistState.isLoading,
                            onPressed: () {
                              final url = _urlController.text.trim();
                              if (url.isNotEmpty) {
                                ref
                                    .read(playlistProvider.notifier)
                                    .fetchPlaylist(url);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Loading state
                if (playlistState.isLoading)
                  const _LoadingIndicator(),

                // Error state
                if (playlistState.error != null)
                  _ErrorBanner(
                    error: playlistState.error!,
                    onRetry: () {
                      final url = _urlController.text.trim();
                      if (url.isNotEmpty) {
                        ref
                            .read(playlistProvider.notifier)
                            .fetchPlaylist(url);
                      }
                    },
                  ),

                // Playlist content
                if (playlistState.videos.isNotEmpty) ...[
                  // Playlist title
                  if (playlistState.playlistTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.album_rounded,
                            color: Color(0xFF1DB954),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              playlistState.playlistTitle!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${playlistState.videos.length} ${tr('videos')}',
                              style: const TextStyle(
                                color: Color(0xFF1DB954),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Select all / Deselect all
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ref.read(playlistProvider.notifier).selectAll();
                        },
                        icon: const Icon(Icons.select_all_rounded, size: 18),
                        label: Text(tr('select_all')),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.white.withValues(alpha: 0.6),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(playlistProvider.notifier)
                              .deselectAll();
                        },
                        icon: const Icon(Icons.deselect_rounded, size: 18),
                        label: Text(tr('deselect_all')),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.white.withValues(alpha: 0.6),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${playlistState.videos.where((v) => v.isSelected).length} ${tr('selected')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Video list
                  ...playlistState.videos
                      .map((video) => PlaylistVideoTile(video: video)),
                  const SizedBox(height: 20),

                  // Format & quality
                  Row(
                    children: [
                      Expanded(child: _buildFormatSelector()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildQualitySelector()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Download selected button
                  _DownloadSelectedButton(
                    count: playlistState.videos
                        .where((v) => v.isSelected)
                        .length,
                    onPressed: () {
                      _downloadSelected(ref, playlistState);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            tr('format'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildFormatOption('MP3', '🎵', DownloadFormat.mp3),
              const SizedBox(width: 4),
              _buildFormatOption('MP4', '🎬', DownloadFormat.mp4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
      String label, String emoji, DownloadFormat format) {
    final isSelected = _selectedFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFormat = format;
            _selectedQuality =
                format == DownloadFormat.mp3 ? '320kbps' : '720p';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1DB954).withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualitySelector() {
    final isVideo = _selectedFormat == DownloadFormat.mp4;
    final qualities =
        isVideo ? AppConstants.videoQualities : AppConstants.audioQualities;

    if (!qualities.contains(_selectedQuality)) {
      _selectedQuality = qualities.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            tr('quality'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedQuality,
              onChanged: (v) {
                if (v != null) setState(() => _selectedQuality = v);
              },
              dropdownColor: const Color(0xFF282828),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1DB954),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: qualities
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadSelected(WidgetRef ref, PlaylistState playlistState) {
    final selected =
        ref.read(playlistProvider.notifier).getSelectedVideos();
    if (selected.isEmpty) return;

    final queueNotifier = ref.read(queueProvider.notifier);

    for (final video in selected) {
      final item = DownloadItem(
        id: const Uuid().v4(),
        url: 'https://www.youtube.com/watch?v=${video.id}',
        platform: 'YouTube',
        format: _selectedFormat,
        quality: _selectedQuality,
        status: DownloadStatus.queued,
        progress: 0.0,
        title: video.title,
        thumbnail: video.thumbnail,
        createdAt: DateTime.now(),
        isPlaylist: true,
        playlistName: playlistState.playlistTitle,
      );
      queueNotifier.addToQueue(item);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selected.length} ${tr('videos_added_to_queue')}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF282828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _FetchButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _FetchButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.search_rounded,
                      color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isLoading ? tr('fetching') : tr('fetch_playlist'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('fetching_playlist'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: Colors.redAccent,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _DownloadSelectedButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _DownloadSelectedButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: count > 0 ? 1.0 : 0.5,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: count > 0 ? onPressed : null,
          icon: const Icon(Icons.download_rounded, size: 20),
          label: Text('${tr('download_selected')} ($count)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
