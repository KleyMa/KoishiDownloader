import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/download_provider.dart';

class QualitySelector extends ConsumerWidget {
  const QualitySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(downloadFormProvider);
    final isVideo = formState.selectedFormat == DownloadFormat.mp4;
    final qualities =
        isVideo ? AppConstants.videoQualities : AppConstants.audioQualities;
    final selectedQuality = formState.selectedQuality;

    // Ensure selected quality is valid for current format
    final validQuality =
        qualities.contains(selectedQuality) ? selectedQuality : qualities.first;

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
          height: 58,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: validQuality,
              onChanged: (value) {
                if (value != null) {
                  ref.read(downloadFormProvider.notifier).setQuality(value);
                }
              },
              dropdownColor: const Color(0xFF282828),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1DB954),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              items: qualities.map((quality) {
              return DropdownMenuItem<String>(
                value: quality,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (quality == validQuality)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        quality,
                        style: TextStyle(
                          color: quality == validQuality
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          fontWeight: quality == validQuality
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_isRecommended(quality, isVideo)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tr('recommended'),
                            style: const TextStyle(
                              color: Color(0xFF1DB954),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        ),
      ],
    );
  }

  bool _isRecommended(String quality, bool isVideo) {
    if (isVideo) return quality == '720p';
    return quality == '320kbps';
  }
}
