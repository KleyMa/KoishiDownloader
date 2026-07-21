import 'package:koishi_downloader/core/constants/app_constants.dart';

/// Immutable model representing a single download task.
///
/// Tracks everything from the initial URL to the final file path, including
/// progress, status, and optional playlist metadata.
class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.url,
    required this.platform,
    required this.format,
    required this.quality,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.title,
    this.thumbnail,
    this.filePath,
    this.errorMessage,
    required this.createdAt,
    this.isPlaylist = false,
    this.playlistName,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// Source URL of the video/audio.
  final String url;

  /// Platform name: youtube, facebook, twitter, instagram, tiktok, other.
  final String platform;

  /// Desired output format.
  final DownloadFormat format;

  /// Desired quality string (e.g. `720p`, `320kbps`).
  final String quality;

  /// Current lifecycle status.
  final DownloadStatus status;

  /// Download progress from `0.0` to `1.0`.
  final double progress;

  /// Media title – populated after [DownloadStatus.fetchingInfo].
  final String? title;

  /// Thumbnail URL – populated after [DownloadStatus.fetchingInfo].
  final String? thumbnail;

  /// Absolute path to the downloaded file – set on [DownloadStatus.completed].
  final String? filePath;

  /// Human-readable error description – set on [DownloadStatus.error].
  final String? errorMessage;

  /// When this item was added to the queue.
  final DateTime createdAt;

  /// Whether this item belongs to a playlist batch.
  final bool isPlaylist;

  /// Name of the parent playlist, if applicable.
  final String? playlistName;

  // ──────────────────────────────────────────────────────────────────────────
  //  copyWith
  // ──────────────────────────────────────────────────────────────────────────

  DownloadItem copyWith({
    String? id,
    String? url,
    String? platform,
    DownloadFormat? format,
    String? quality,
    DownloadStatus? status,
    double? progress,
    String? title,
    String? thumbnail,
    String? filePath,
    String? errorMessage,
    DateTime? createdAt,
    bool? isPlaylist,
    String? playlistName,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      isPlaylist: isPlaylist ?? this.isPlaylist,
      playlistName: playlistName ?? this.playlistName,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  JSON serialisation
  // ──────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'platform': platform,
      'format': format.name,
      'quality': quality,
      'status': status.name,
      'progress': progress,
      'title': title,
      'thumbnail': thumbnail,
      'filePath': filePath,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'isPlaylist': isPlaylist,
      'playlistName': playlistName,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      url: json['url'] as String,
      platform: json['platform'] as String,
      format: DownloadFormat.fromString(json['format'] as String),
      quality: json['quality'] as String,
      status: DownloadStatus.fromString(json['status'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String?,
      thumbnail: json['thumbnail'] as String?,
      filePath: json['filePath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPlaylist: json['isPlaylist'] as bool? ?? false,
      playlistName: json['playlistName'] as String?,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Equality & hashCode
  // ──────────────────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DownloadItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DownloadItem(id: $id, title: $title, status: ${status.name}, '
      'progress: ${(progress * 100).toStringAsFixed(0)}%)';
}
