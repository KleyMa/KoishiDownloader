import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/download_provider.dart';

class UrlInputCard extends ConsumerStatefulWidget {
  const UrlInputCard({super.key});

  @override
  ConsumerState<UrlInputCard> createState() => _UrlInputCardState();
}

class _UrlInputCardState extends ConsumerState<UrlInputCard> with WidgetsBindingObserver {
  late final TextEditingController _controller;
  bool _isFocused = false;
  static const _sharedChannel = MethodChannel('app.channel.shared.data');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController();
    _checkSharedText();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSharedText();
    }
  }

  Future<void> _checkSharedText() async {
    try {
      final String? sharedText = await _sharedChannel.invokeMethod('getSharedText');
      if (sharedText != null && sharedText.isNotEmpty) {
        _controller.text = sharedText;
        ref.read(downloadFormProvider.notifier).setUrl(sharedText);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      ref.read(downloadFormProvider.notifier).setUrl(data.text!);
    }
  }

  void _clearField() {
    _controller.clear();
    ref.read(downloadFormProvider.notifier).setUrl('');
  }


  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(downloadFormProvider);

    return Card(
      color: const Color(0xFF282828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isFocused
              ? const Color(0xFF1DB954).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Focus(
                onFocusChange: (focused) {
                  setState(() => _isFocused = focused);
                },
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                  onChanged: (value) {
                    ref.read(downloadFormProvider.notifier).setUrl(value);
                  },
                  decoration: InputDecoration(
                    hintText: tr('url_hint'),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF181818),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.link_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isFocused || formState.currentUrl.isNotEmpty)
                          _buildIconButton(
                            icon: Icons.close_rounded,
                            onTap: _clearField,
                            tooltip: tr('clear'),
                          ),
                        _buildIconButton(
                          icon: Icons.content_paste_rounded,
                          onTap: _pasteFromClipboard,
                          tooltip: tr('paste_url'),
                          isAccent: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Removed Platform chips row
              // Playlist detection banner
              if (formState.currentUrl.isNotEmpty &&
                  _isPlaylistUrl(formState.currentUrl))
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF1DB954).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          const Color(0xFF1DB954).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.playlist_play_rounded,
                        color: Color(0xFF1DB954),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('playlist_detected'),
                          style: const TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(downloadFormProvider.notifier)
                              .togglePlaylistMode();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1DB954),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          formState.isPlaylistMode
                              ? tr('single_mode')
                              : tr('playlist_mode'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isAccent = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isAccent
                  ? const Color(0xFF1DB954)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  bool _isPlaylistUrl(String url) {
    return url.contains('playlist') ||
        url.contains('list=') ||
        url.contains('/sets/');
  }

}

