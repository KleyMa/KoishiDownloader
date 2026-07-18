import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';

class DefaultQualitySetting extends ConsumerWidget {
  const DefaultQualitySetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        _QualityTile(
          icon: Icons.videocam_rounded,
          iconColor: Colors.blueAccent,
          title: tr('default_video_quality'),
          subtitle: tr('default_video_quality_desc'),
          value: settings.defaultVideoQuality,
          options: AppConstants.videoQualities,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateVideoQuality(value);
          },
        ),
        Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 24,
          indent: 54,
        ),
        _QualityTile(
          icon: Icons.music_note_rounded,
          iconColor: const Color(0xFF1DB954),
          title: tr('default_audio_quality'),
          subtitle: tr('default_audio_quality_desc'),
          value: settings.defaultAudioQuality,
          options: AppConstants.audioQualities,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateAudioQuality(value);
          },
        ),
      ],
    );
  }
}

class _QualityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _QualityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                dropdownColor: const Color(0xFF282828),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                borderRadius: BorderRadius.circular(12),
                items: options.map((q) {
                  return DropdownMenuItem(
                    value: q,
                    child: Text(q),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
