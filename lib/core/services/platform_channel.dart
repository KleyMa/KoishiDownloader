import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:music_downloader/core/constants/app_constants.dart';

/// Dart-side wrapper around the platform channels that communicate with the
/// Kotlin/yt-dlp native layer.
///
/// All methods translate [PlatformException]s into human-readable messages and
/// rethrow as [YtDlpException] so callers can handle errors uniformly.
class YtDlpService {
  YtDlpService();

  static const MethodChannel _channel = MethodChannel(
    AppConstants.ytdlpChannel,
  );

  static const EventChannel _progressChannel = EventChannel(
    AppConstants.progressChannel,
  );

  /// Tracks whether [initYtDlp] has completed successfully.
  static bool _initialized = false;

  /// Guards concurrent init calls so only one runs at a time.
  static Completer<bool>? _initCompleter;

  // ──────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialise the yt-dlp binary on the native side.
  ///
  /// Returns `true` when the binary is ready to accept commands.
  /// Safe to call multiple times — subsequent calls return immediately.
  Future<bool> initYtDlp() async {
    if (_initialized) return true;

    // If another call is already in flight, wait for it
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<bool>();
    debugPrint('[YtDlpService] Initializing yt-dlp...');
    try {
      final result = await _channel.invokeMethod<bool>('initYtDlp');
      _initialized = result ?? false;
      debugPrint('[YtDlpService] yt-dlp initialized: $_initialized');
      _initCompleter!.complete(_initialized);
      return _initialized;
    } on PlatformException catch (e) {
      debugPrint('[YtDlpService] ❌ INIT FAILED: ${e.code} - ${e.message}');
      debugPrint('[YtDlpService] Native stack trace:\n${e.details}');
      _initCompleter!.completeError(
        YtDlpException(
          'Failed to initialise yt-dlp: ${e.message}',
          code: e.code,
        ),
      );
      rethrow;
    } on MissingPluginException {
      debugPrint('[YtDlpService] ❌ MISSING PLUGIN - native side not configured');
      _initCompleter!.completeError(
        YtDlpException(
          'yt-dlp platform channel not available. '
          'Ensure the native side is properly configured.',
          code: 'MISSING_PLUGIN',
        ),
      );
      rethrow;
    } finally {
      // Allow future retries if init failed
      if (!_initialized) {
        _initCompleter = null;
      }
    }
  }

  /// Ensures yt-dlp is initialized before performing any operation.
  /// Automatically calls [initYtDlp] if not yet done.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await initYtDlp();
  }

  /// Updates yt-dlp to the latest version.
  ///
  /// Returns a status message from the native side (e.g. the new version).
  Future<String> updateYtDlp() async {
    try {
      final result = await _channel.invokeMethod<String>('updateYtDlp');
      return result ?? 'Update completed';
    } on PlatformException catch (e) {
      throw YtDlpException(
        'Failed to update yt-dlp: ${e.message}',
        code: e.code,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Media info
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetches metadata for a single video/audio URL.
  ///
  /// Returns a map with keys such as `title`, `thumbnail`, `duration`,
  /// `formats`, etc.
  Future<Map<String, dynamic>> getVideoInfo(String url) async {
    try {
      final result = await _channel.invokeMethod<Map>('getVideoInfo', {
        'url': url,
      });
      if (result == null) {
        throw YtDlpException(
          'No information returned for the provided URL.',
          code: 'NULL_RESULT',
        );
      }
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw YtDlpException(
        'Failed to fetch video info: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Fetches metadata for every item in a playlist URL.
  ///
  /// Returns a list of maps, one per playlist entry.
  Future<List<Map<String, dynamic>>> getPlaylistInfo(String url) async {
    try {
      final result = await _channel.invokeMethod<List>('getPlaylistInfo', {
        'url': url,
      });
      if (result == null) {
        throw YtDlpException(
          'No playlist information returned.',
          code: 'NULL_RESULT',
        );
      }
      return result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on PlatformException catch (e) {
      throw YtDlpException(
        'Failed to fetch playlist info: ${e.message}',
        code: e.code,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Download control
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts a download and returns the native-side task ID that can later be
  /// used with [cancelDownload].
  ///
  /// * [url]        – The media URL.
  /// * [format]     – `mp3` or `mp4`.
  /// * [quality]    – e.g. `720p`, `320kbps`.
  /// * [outputPath] – Absolute directory path to save the file.
  Future<String> startDownload({
    required String taskId,
    required String url,
    required String format,
    required String quality,
    required String outputPath,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('startDownload', {
        'taskId': taskId,
        'url': url,
        'format': format,
        'quality': quality,
        'outputPath': outputPath,
      });
      if (result == null) {
        throw YtDlpException(
          'Download start returned no task ID.',
          code: 'NULL_RESULT',
        );
      }
      return result;
    } on PlatformException catch (e) {
      throw YtDlpException(
        'Failed to start download: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Cancels an in-progress download identified by [taskId].
  ///
  /// Returns `true` if the cancellation was acknowledged by the native side.
  Future<bool> cancelDownload(String taskId) async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelDownload', {
        'taskId': taskId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw YtDlpException(
        'Failed to cancel download: ${e.message}',
        code: e.code,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Progress stream
  // ──────────────────────────────────────────────────────────────────────────

  /// A broadcast stream of download-progress events emitted by the native
  /// side.
  ///
  /// Each event is a map containing at least:
  /// * `taskId`   – the download task identifier
  /// * `progress` – a double from 0.0 to 1.0
  /// * `status`   – one of the [DownloadStatus] names
  ///
  /// Additional keys (e.g. `speed`, `eta`, `filePath`) may be present
  /// depending on the event type.
  Stream<Map<String, dynamic>> get progressStream {
    return _progressChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }
}

/// Custom exception thrown by [YtDlpService] methods.
class YtDlpException implements Exception {
  const YtDlpException(this.message, {this.code = 'UNKNOWN'});

  /// Human-readable error description.
  final String message;

  /// Optional error code from the platform side.
  final String code;

  @override
  String toString() => 'YtDlpException($code): $message';
}
