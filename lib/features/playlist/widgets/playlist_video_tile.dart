import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/playlist_provider.dart';

class PlaylistVideoTile extends ConsumerWidget {
  final PlaylistVideoItem video;

  const PlaylistVideoTile({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: video.isSelected
            ? const Color(0xFF1DB954).withValues(alpha: 0.06)
            : const Color(0xFF282828),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: video.isSelected
              ? const Color(0xFF1DB954).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref
                .read(playlistProvider.notifier)
                .toggleVideoSelection(video.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: video.isSelected
                        ? const Color(0xFF1DB954)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: video.isSelected
                          ? const Color(0xFF1DB954)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: video.isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Thumbnail placeholder
                Container(
                  width: 56,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(8),
                    image: video.thumbnail != null
                        ? DecorationImage(
                            image: NetworkImage(video.thumbnail!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: video.thumbnail == null
                      ? Icon(
                          Icons.movie_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Title and duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: TextStyle(
                          color: video.isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (video.duration != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video.duration!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
