import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

import 'package:file_picker/file_picker.dart';

/// Opens the system folder-picker and returns the selected path,
/// or null if the user cancelled.
Future<String?> _pickDirectory(String dialogTitle) async {
  try {
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    return result;
  } catch (e) {
    return null;
  }
}

class DownloadPathSetting extends ConsumerWidget {
  const DownloadPathSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        _PathTile(
          icon: Icons.videocam_rounded,
          iconColor: Colors.blueAccent,
          title: tr('video_download_path'),
          path: settings.videoDownloadPath,
          onTap: () async {
            final result = await _pickDirectory(tr('select_video_folder'));
            if (result != null) {
              ref.read(settingsProvider.notifier).updateVideoPath(result);
            }
          },
        ),
        Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 24,
          indent: 54,
        ),
        _PathTile(
          icon: Icons.music_note_rounded,
          iconColor: const Color(0xFF1DB954),
          title: tr('music_download_path'),
          path: settings.musicDownloadPath,
          onTap: () async {
            final result = await _pickDirectory(tr('select_music_folder'));
            if (result != null) {
              ref.read(settingsProvider.notifier).updateMusicPath(result);
            }
          },
        ),
      ],
    );
  }
}

class _PathTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String path;
  final VoidCallback onTap;

  const _PathTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          path,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF1DB954),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
