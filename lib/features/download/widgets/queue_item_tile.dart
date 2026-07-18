import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_constants.dart';
import '../models/download_item.dart';
import '../providers/queue_provider.dart';

class QueueItemTile extends ConsumerStatefulWidget {
  final DownloadItem item;
  final int index;

  const QueueItemTile({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  ConsumerState<QueueItemTile> createState() => _QueueItemTileState();
}

class _QueueItemTileState extends ConsumerState<QueueItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 50).clamp(0, 200)),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _slideController,
        child: Dismissible(
          key: ValueKey('dismiss_${item.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            ref.read(queueProvider.notifier).removeFromQueue(item.id);
          },
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _getBorderColor(item.status),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Drag handle
                      ReorderableDragStartListener(
                        index: widget.index,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: Colors.white.withValues(alpha: 0.2),
                            size: 20,
                          ),
                        ),
                      ),
                      // Thumbnail or platform icon
                      _buildThumbnail(item),
                      const SizedBox(width: 12),
                      // Title and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title ?? (item.status == DownloadStatus.queued ? 'En cola...' : 'Cargando título...'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildStatusBadge(item),
                                _buildFormatChip(item.format),
                                _buildQualityChip(item.quality),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action buttons
                      _buildActionButtons(context, item),
                    ],
                  ),
                ),
                // Progress bar
                if (_showProgress(item.status))
                  _buildProgressBar(item.progress, item.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(DownloadItem item) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(10),
        image: item.thumbnail != null
            ? DecorationImage(
                image: NetworkImage(item.thumbnail!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: item.thumbnail == null
          ? Icon(
              _getPlatformIcon(item.platform),
              color: Colors.white.withValues(alpha: 0.3),
              size: 24,
            )
          : null,
    );
  }

  Widget _buildStatusBadge(DownloadItem item) {
    final config = _getStatusConfig(item);
    final status = item.status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == DownloadStatus.downloading ||
              status == DownloadStatus.fetchingInfo ||
              status == DownloadStatus.converting)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: config.color,
                ),
              ),
            ),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(DownloadFormat format) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        format == DownloadFormat.mp3 ? 'MP3' : 'MP4',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQualityChip(String quality) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        quality,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DownloadItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.status.isActive)
          _iconButton(
            icon: Icons.pause_rounded,
            color: Colors.orangeAccent,
            tooltip: tr('pause'),
            onTap: () => ref.read(queueProvider.notifier).pauseItem(item.id),
          )
        else if (item.status == DownloadStatus.paused)
          _iconButton(
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFF1DB954),
            tooltip: tr('resume'),
            onTap: () => ref.read(queueProvider.notifier).resumeItem(item.id),
          )
        else if (item.status == DownloadStatus.error || item.status == DownloadStatus.cancelled)
          _iconButton(
            icon: Icons.refresh_rounded,
            color: const Color(0xFF1DB954),
            tooltip: tr('retry'),
            onTap: () => ref.read(queueProvider.notifier).retryItem(item.id),
          )
        else if (item.status == DownloadStatus.completed)
          _iconButton(
            icon: Icons.folder_rounded,
            color: const Color(0xFF1DB954),
            tooltip: 'Abrir carpeta',
            onTap: () => _openFolder(item.filePath ?? ''),
          ),
        
        _iconButton(
          icon: Icons.delete_outline_rounded,
          color: Colors.redAccent,
          tooltip: tr('remove'),
          onTap: () => _confirmDelete(context, item),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, DownloadItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('confirm_delete'), style: const TextStyle(color: Colors.white)),
        content: Text(
          tr('confirm_delete_desc'),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              ref.read(queueProvider.notifier).removeItem(item.id);
              Navigator.pop(context);
            },
            child: Text(tr('remove'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, DownloadStatus status) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: status == DownloadStatus.fetchingInfo ? null : value.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              status == DownloadStatus.converting
                  ? Colors.orangeAccent
                  : const Color(0xFF1DB954),
            ),
          );
        },
      ),
    );
  }

  bool _showProgress(DownloadStatus status) {
    return status == DownloadStatus.downloading ||
        status == DownloadStatus.fetchingInfo ||
        status == DownloadStatus.converting;
  }

  Color _getBorderColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.fetchingInfo:
        return const Color(0xFF1DB954).withValues(alpha: 0.2);
      case DownloadStatus.converting:
        return Colors.orangeAccent.withValues(alpha: 0.2);
      case DownloadStatus.completed:
        return const Color(0xFF1DB954).withValues(alpha: 0.15);
      case DownloadStatus.error:
        return Colors.redAccent.withValues(alpha: 0.2);
      default:
        return Colors.white.withValues(alpha: 0.04);
    }
  }

  _StatusConfig _getStatusConfig(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.queued:
        return _StatusConfig(
          color: Colors.white.withValues(alpha: 0.5),
          label: tr('queue_status_queued'),
        );
      case DownloadStatus.fetchingInfo:
        return _StatusConfig(
          color: Colors.blueAccent,
          label: tr('queue_status_fetching_info'),
        );
      case DownloadStatus.downloading:
        final percent = (item.progress * 100).toInt();
        return _StatusConfig(
          color: const Color(0xFF1DB954),
          label: tr('queue_status_downloading_percent', args: [percent.toString()]),
        );
      case DownloadStatus.converting:
        return _StatusConfig(
          color: Colors.orangeAccent,
          label: tr('queue_status_converting'),
        );
      case DownloadStatus.completed:
        return _StatusConfig(
          color: const Color(0xFF1DB954),
          label: tr('queue_status_completed'),
        );
      case DownloadStatus.error:
        return _StatusConfig(
          color: Colors.redAccent,
          label: tr('queue_status_error'),
        );
      case DownloadStatus.cancelled:
        return _StatusConfig(
          color: Colors.white.withValues(alpha: 0.4),
          label: tr('queue_status_cancelled'),
        );
      case DownloadStatus.paused:
        return _StatusConfig(
          color: Colors.orangeAccent,
          label: tr('queue_status_paused'),
        );
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'YouTube':
        return Icons.play_circle_fill_rounded;
      case 'Facebook':
        return Icons.facebook_rounded;
      case 'Twitter/X':
        return Icons.alternate_email_rounded;
      case 'Instagram':
        return Icons.camera_alt_rounded;
      case 'TikTok':
        return Icons.music_note_rounded;
      default:
        return Icons.language_rounded;
    }
  }



  void _openFolder(String path) {
    if (path.isNotEmpty) {
      OpenFilex.open(path);
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;

  const _StatusConfig({required this.color, required this.label});
}
