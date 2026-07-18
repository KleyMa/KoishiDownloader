import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/platform_channel.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/download_item.dart';

final ytDlpServiceProvider = Provider<YtDlpService>((ref) {
  return YtDlpService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

class QueueNotifier extends StateNotifier<List<DownloadItem>> {
  final Ref _ref;
  bool _isProcessing = false;
  StreamSubscription<Map<String, dynamic>>? _progressSubscription;
  String? _currentTaskId;

  QueueNotifier(this._ref) : super([]);

  bool get isProcessing => _isProcessing;

  void addToQueue(DownloadItem item) {
    state = [...state, item];
    if (!_isProcessing) {
      startProcessingQueue();
    }
  }

  void removeFromQueue(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void updateItemProgress(String id, double progress) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(progress: progress) else item,
    ];
  }

  void updateItemStatus(
    String id,
    DownloadStatus status, {
    String? title,
    String? thumbnail,
    String? filePath,
    String? errorMessage,
  }) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: status,
            title: title ?? item.title,
            thumbnail: thumbnail ?? item.thumbnail,
            filePath: filePath ?? item.filePath,
            errorMessage: errorMessage,
          )
        else
          item,
    ];
  }

  Future<void> cancelItem(String id) async {
    final ytDlp = _ref.read(ytDlpServiceProvider);
    final item = state.firstWhere((i) => i.id == id, orElse: () => state.first);
    if (item.status.isActive && _currentTaskId != null) {
      await ytDlp.cancelDownload(_currentTaskId!);
    }
    updateItemStatus(id, DownloadStatus.cancelled);
  }

  Future<void> removeItem(String id) async {
    await cancelItem(id);
    removeFromQueue(id);
  }

  void retryItem(String id) {
    updateItemStatus(id, DownloadStatus.queued, errorMessage: null);
    updateItemProgress(id, 0.0);
    if (!_isProcessing) {
      startProcessingQueue();
    }
  }

  void clearCompleted() {
    state = state
        .where((item) =>
            item.status != DownloadStatus.completed &&
            item.status != DownloadStatus.cancelled)
        .toList();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final items = List<DownloadItem>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }

  DownloadItem? getNextInQueue() {
    try {
      return state.firstWhere(
        (item) => item.status == DownloadStatus.queued,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> startProcessingQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final ytDlp = _ref.read(ytDlpServiceProvider);
    final notifications = _ref.read(notificationServiceProvider);

    while (true) {
      final nextItem = getNextInQueue();
      if (nextItem == null) {
        _isProcessing = false;
        return;
      }

      final item = nextItem;
      final notificationId = item.id.hashCode.abs() % 100000;

      try {
        // Phase 1: Fetching info
        updateItemStatus(item.id, DownloadStatus.fetchingInfo);

        // Ensure yt-dlp is initialized before any operation
        await ytDlp.ensureInitialized();

        final info = await ytDlp.getVideoInfo(item.url);
        final title = info['title'] as String? ?? item.url;
        final thumbnail = info['thumbnail'] as String?;
        updateItemStatus(
          item.id,
          DownloadStatus.downloading,
          title: title,
          thumbnail: thumbnail,
        );

        // Phase 2: Downloading
        final settings = _ref.read(settingsProvider);
        final outputPath = item.format == DownloadFormat.mp3
            ? settings.musicDownloadPath
            : settings.videoDownloadPath;

        _currentTaskId = item.id;
        
        _progressSubscription = ytDlp.progressStream.listen((data) {
          final taskId = data['taskId'] as String?;
          if (taskId == _currentTaskId) {
            final rawProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
            final progress = (rawProgress < 0.0 ? 0.0 : rawProgress) / 100.0; // Scale 0-100 to 0.0-1.0
            final status = data['status'] as String?;

            updateItemProgress(item.id, progress);
            notifications.showProgressNotification(
              notificationId,
              title,
              (progress * 100).round(),
            );

            if (status == 'converting') {
              updateItemStatus(item.id, DownloadStatus.converting);
            } else if (status == 'completed') {
              updateItemStatus(item.id, DownloadStatus.completed);
            } else if (status == 'error') {
              final line = data['line'] as String?;
              updateItemStatus(item.id, DownloadStatus.error, errorMessage: line);
            }
          }
        });

        await ytDlp.startDownload(
          taskId: item.id,
          url: item.url,
          format: item.format.name,
          quality: item.quality,
          outputPath: outputPath,
        );

        // Wait for download to complete via progress stream
        await _waitForCompletion(item.id);

        // Check final status
        final currentItem = state.firstWhere((i) => i.id == item.id);
        if (currentItem.status == DownloadStatus.cancelled) {
          await notifications.cancelNotification(notificationId);
          continue;
        }

        if (currentItem.status == DownloadStatus.error) {
          // It already showed error, just continue
          continue;
        }

        updateItemStatus(item.id, DownloadStatus.completed, filePath: outputPath);
        updateItemProgress(item.id, 1.0);
        await notifications.showCompletedNotification(notificationId, title);
      } catch (e, stackTrace) {
        debugPrint('[QueueNotifier] ❌ Download error for ${item.url}');
        debugPrint('[QueueNotifier] Error: $e');
        debugPrint('[QueueNotifier] Stack trace:\n$stackTrace');
        updateItemStatus(
          item.id,
          DownloadStatus.error,
          errorMessage: e.toString(),
        );
        await notifications.showErrorNotification(
          notificationId,
          item.title ?? item.url,
          e.toString(),
        );
      }

      _progressSubscription?.cancel();
      _currentTaskId = null;
    }
  }

  Future<void> _waitForCompletion(String itemId) async {
    final completer = Completer<void>();

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        completer.complete();
        return;
      }

      try {
        final item = state.firstWhere((i) => i.id == itemId);
        if (item.status == DownloadStatus.completed ||
            item.status == DownloadStatus.error ||
            item.status == DownloadStatus.cancelled) {
          timer.cancel();
          completer.complete();
        }
      } catch (_) {
        timer.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }
}

final queueProvider =
    StateNotifierProvider<QueueNotifier, List<DownloadItem>>((ref) {
  return QueueNotifier(ref);
});
