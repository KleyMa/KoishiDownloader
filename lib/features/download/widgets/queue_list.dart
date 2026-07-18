import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/queue_provider.dart';
import 'queue_item_tile.dart';

class QueueList extends ConsumerWidget {
  const QueueList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);


    if (queue.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final animValue = Curves.easeInOut.transform(animation.value);
                final elevation = 6.0 * animValue;
                final scale = 1.0 + 0.02 * animValue;
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    shadowColor:
                        const Color(0xFF1DB954).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemCount: queue.length,
          onReorder: (oldIndex, newIndex) {
            ref.read(queueProvider.notifier).reorderQueue(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final item = queue[index];
            return QueueItemTile(
              key: ValueKey(item.id),
              item: item,
              index: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.queue_music_rounded,
                size: 36,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('empty_queue'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('empty_queue_subtitle'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

