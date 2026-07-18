import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/download_provider.dart';

class UrlInputCard extends ConsumerStatefulWidget {
  const UrlInputCard({super.key});

  @override
  ConsumerState<UrlInputCard> createState() => _UrlInputCardState();
}

class _UrlInputCardState extends ConsumerState<UrlInputCard>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _animController;
  late final Animation<double> _glowAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
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

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'YouTube':
        return Icons.play_circle_fill_rounded;
      case 'Facebook':
        return Icons.facebook_rounded;
      case 'Twitter/X':
        return Icons.alternate_email_rounded;
      case 'Instagram':
        return Icons.camera_alt_rounded;
      case 'TikTok':
        return Icons.music_note_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  String _getPlatformName(String platform) {
    switch (platform) {
      case 'YouTube':
        return tr('platform_youtube');
      case 'Facebook':
        return tr('platform_facebook');
      case 'Twitter/X':
        return tr('platform_twitter');
      case 'Instagram':
        return tr('platform_instagram');
      case 'TikTok':
        return tr('platform_tiktok');
      case 'Other':
        return tr('platform_other');
      default:
        return platform;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(downloadFormProvider);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _isFocused
                ? LinearGradient(
                    colors: [
                      const Color(0xFF1DB954)
                          .withValues(alpha: 0.3 * _glowAnimation.value),
                      const Color(0xFF1DB954)
                          .withValues(alpha: 0.1 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF1DB954)
                          .withValues(alpha: 0.15 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Card(
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
                        if (formState.currentUrl.isNotEmpty)
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
              const SizedBox(height: 14),
              // Platform chips
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: ref.watch(settingsProvider).selectedPlatforms.map((platform) {
                          final isSelected = formState.selectedPlatform == platform;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: FilterChip(
                                  selected: isSelected,
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getPlatformIcon(platform),
                                          size: 14,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _getPlatformName(platform),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF181818),
                                  selectedColor:
                                      const Color(0xFF1DB954).withValues(alpha: 0.25),
                                  checkmarkColor: const Color(0xFF1DB954),
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF1DB954)
                                              .withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  onSelected: (_) {
                                    ref
                                        .read(downloadFormProvider.notifier)
                                        .setPlatform(platform);
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showPlatformPicker(context, ref.read(settingsProvider).selectedPlatforms),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF181818),
                        foregroundColor: Colors.white.withValues(alpha: 0.7),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  void _showPlatformPicker(BuildContext context, List<String> currentPlatforms) {
    final tempPlatforms = List<String>.from(currentPlatforms);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF282828),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Select Platforms (Max 3)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppConstants.platforms.length,
                  itemBuilder: (context, index) {
                    final platform = AppConstants.platforms[index];
                    final isChecked = tempPlatforms.contains(platform);
                    return CheckboxListTile(
                      title: Text(
                        platform,
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: isChecked,
                      activeColor: const Color(0xFF1DB954),
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (tempPlatforms.length < 3) {
                              tempPlatforms.add(platform);
                            }
                          } else {
                            if (tempPlatforms.length > 1) {
                              tempPlatforms.remove(platform);
                            }
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).updateSelectedPlatforms(tempPlatforms);
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Color(0xFF1DB954))),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

