import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
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
    
    updateItemStatus(id, DownloadStatus.cancelled); // Sync update

    if (item.status.isActive && _currentTaskId == id) {
      await ytDlp.cancelDownload(id);
    }
  }

  Future<void> pauseItem(String id) async {
    final ytDlp = _ref.read(ytDlpServiceProvider);
    final item = state.firstWhere((i) => i.id == id, orElse: () => state.first);
    
    updateItemStatus(id, DownloadStatus.paused); // Sync update

    if (item.status.isActive && _currentTaskId == id) {
      await ytDlp.cancelDownload(id);
    }
  }

  void resumeItem(String id) {
    updateItemStatus(id, DownloadStatus.queued, errorMessage: null);
    if (!_isProcessing) {
      startProcessingQueue();
    }
  }

  Future<void> removeItem(String id) async {
    final ytDlp = _ref.read(ytDlpServiceProvider);
    final item = state.firstWhere((i) => i.id == id, orElse: () => state.first);
    
    updateItemStatus(id, DownloadStatus.cancelled); // Sync update to avoid completion

    if (item.status.isActive && _currentTaskId == id) {
      await ytDlp.cancelDownload(id);
    }
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
        String? downloadedFilePath;
        
        _progressSubscription = ytDlp.progressStream.listen((data) {
          final taskId = data['taskId'] as String?;
          if (taskId == _currentTaskId) {
            final currentItem = state.firstWhere((i) => i.id == item.id, orElse: () => item);
            if (currentItem.status == DownloadStatus.paused || currentItem.status == DownloadStatus.cancelled) {
              return;
            }

            final rawProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
            final progress = (rawProgress < 0.0 ? 0.0 : rawProgress) / 100.0; // Scale 0-100 to 0.0-1.0
            final status = data['status'] as String?;

            updateItemProgress(item.id, progress);
            notifications.showProgressNotification(
              notificationId,
              title,
              tr('queue_status_downloading_percent', args: ['${(progress * 100).round()}']),
              (progress * 100).round(),
            );

            if (status == 'converting') {
              updateItemStatus(item.id, DownloadStatus.converting);
            } else if (status == 'completed') {
              downloadedFilePath = data['filePath'] as String?;
              updateItemStatus(item.id, DownloadStatus.completed);
            } else if (status == 'error') {
              final line = data['line'] as String?;
              String errorMsg = line ?? tr('error_download_failed');
              if (errorMsg.contains('Video unavailable')) {
                errorMsg = tr('error_video_unavailable');
              } else if (errorMsg.contains('Sign in to confirm')) {
                errorMsg = tr('error_sign_in_bot');
              } else if (errorMsg.contains('Private video')) {
                errorMsg = tr('error_private_video');
              }
              updateItemStatus(item.id, DownloadStatus.error, errorMessage: errorMsg);
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
        if (currentItem.status == DownloadStatus.cancelled || currentItem.status == DownloadStatus.paused) {
          await notifications.cancelNotification(notificationId);
          continue;
        }

        if (currentItem.status == DownloadStatus.error) {
          // It already showed error, just continue
          continue;
        }

        String finalFilePath = outputPath;
        if (item.format == DownloadFormat.mp3 && downloadedFilePath != null && !downloadedFilePath!.endsWith('.mp3')) {
          updateItemStatus(item.id, DownloadStatus.converting);
          notifications.showProgressNotification(notificationId, title, "Converting to MP3...", 100);
          
          final rawFile = File(downloadedFilePath!);
          final mp3FilePath = downloadedFilePath!.replaceAll(RegExp(r'\.[^.]+$'), '.mp3');
          
          final bitrateStr = item.quality.replaceAll(RegExp(r'[^\d]'), '');
          final bitrate = bitrateStr.isEmpty ? '320' : bitrateStr;
          
          final session = await FFmpegKit.execute('-y -i "${rawFile.path}" -vn -b:a ${bitrate}k "$mp3FilePath"');
          final returnCode = await session.getReturnCode();
          
          if (ReturnCode.isSuccess(returnCode)) {
            if (rawFile.existsSync()) rawFile.deleteSync();
            finalFilePath = mp3FilePath;
          } else {
            updateItemStatus(item.id, DownloadStatus.error, errorMessage: 'FFmpeg native JNI conversion failed');
            await notifications.showErrorNotification(notificationId, title, 'Failed to convert audio to MP3');
            continue;
          }
        } else if (downloadedFilePath != null) {
          finalFilePath = downloadedFilePath!;
        }

        updateItemStatus(item.id, DownloadStatus.completed, filePath: finalFilePath);
        updateItemProgress(item.id, 1.0);
        
        // Scan the final file so it appears in the music library immediately
        await ytDlp.scanFile(finalFilePath);
        await notifications.showCompletedNotification(notificationId, title);
      } catch (e, stackTrace) {
        debugPrint('[QueueNotifier] ❌ Download error for ${item.url}');
        debugPrint('[QueueNotifier] Error: $e');
        debugPrint('[QueueNotifier] Stack trace:\n$stackTrace');

        final currentItem = state.firstWhere((i) => i.id == item.id, orElse: () => item);
        if (currentItem.status == DownloadStatus.paused || currentItem.status == DownloadStatus.cancelled) {
          _progressSubscription?.cancel();
          _currentTaskId = null;
          continue;
        }

        String errorMsg = e.toString();
        if (errorMsg.contains('Video unavailable')) {
          errorMsg = tr('error_video_unavailable');
        } else if (errorMsg.contains('Sign in to confirm')) {
          errorMsg = tr('error_sign_in_bot');
        } else if (errorMsg.contains('Private video')) {
          errorMsg = tr('error_private_video');
        } else {
          errorMsg = tr('error_download_failed');
        }

        updateItemStatus(
          item.id,
          DownloadStatus.error,
          errorMessage: errorMsg,
        );
        await notifications.showErrorNotification(
          notificationId,
          item.title ?? item.url,
          errorMsg,
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
            item.status == DownloadStatus.cancelled ||
            item.status == DownloadStatus.paused) {
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
