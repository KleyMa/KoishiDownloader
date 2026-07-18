import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/download_provider.dart';

class FormatSelector extends ConsumerWidget {
  const FormatSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFormat = ref.watch(
      downloadFormProvider.select((s) => s.selectedFormat),
    );

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
          height: 58,
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
              _FormatOption(
                label: 'MP3',
                icon: Icons.music_note_rounded,
                isSelected: selectedFormat == DownloadFormat.mp3,
                onTap: () {
                  ref
                      .read(downloadFormProvider.notifier)
                      .setFormat(DownloadFormat.mp3);
                },
              ),
              const SizedBox(width: 4),
              _FormatOption(
                label: 'MP4',
                icon: Icons.videocam_rounded,
                isSelected: selectedFormat == DownloadFormat.mp4,
                onTap: () {
                  ref
                      .read(downloadFormProvider.notifier)
                      .setFormat(DownloadFormat.mp4);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1DB954).withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1DB954)
                          .withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
