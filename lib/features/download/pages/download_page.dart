import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/download_item.dart';
import '../providers/download_provider.dart';
import '../providers/queue_provider.dart';
import '../widgets/format_selector.dart';
import '../widgets/quality_selector.dart';
import '../widgets/queue_list.dart';
import '../widgets/url_input_card.dart';

class DownloadPage extends ConsumerWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(downloadFormProvider);
    final queue = ref.watch(queueProvider);
    final queueNotifier = ref.read(queueProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF121212),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  tr('app_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1DB954).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // URL Input
                const UrlInputCard(),
                const SizedBox(height: 20),

                // Format and Quality Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: FormatSelector()),
                    SizedBox(width: 16),
                    Expanded(child: QualitySelector()),
                  ],
                ),
                const SizedBox(height: 24),

                // Add to Queue Button
                _AddToQueueButton(
                  isEnabled: formState.currentUrl.isNotEmpty,
                  onPressed: () {
                    if (formState.currentUrl.isEmpty) return;

                    final item = DownloadItem(
                      id: const Uuid().v4(),
                      url: formState.currentUrl,
                      platform: formState.selectedPlatform,
                      format: formState.selectedFormat,
                      quality: formState.selectedQuality,
                      status: DownloadStatus.queued,
                      progress: 0.0,
                      createdAt: DateTime.now(),
                      isPlaylist: formState.isPlaylistMode,
                    );

                    queueNotifier.addToQueue(item);
                    ref.read(downloadFormProvider.notifier).resetForm();
                  },
                ),
                const SizedBox(height: 32),

                // Queue header
                Row(
                  children: [
                    const Icon(
                      Icons.queue_rounded,
                      color: Color(0xFF1DB954),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('download_queue'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (queue.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${queue.length}',
                          style: const TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (queue.isNotEmpty &&
                        !queueNotifier.isProcessing &&
                        queue.any(
                            (i) => i.status == DownloadStatus.queued))
                      _StartQueueButton(
                        onPressed: () {
                          queueNotifier.startProcessingQueue();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Queue List
                const QueueList(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToQueueButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _AddToQueueButton({
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isEnabled
            ? const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isEnabled ? null : Colors.white.withValues(alpha: 0.06),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: isEnabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  tr('add_to_queue'),
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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

class _StartQueueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartQueueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF1DB954).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF1DB954),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                tr('start'),
                style: const TextStyle(
                  color: Color(0xFF1DB954),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
