import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../providers/audio_player_providers.dart';
import 'package:prism/l10n/l10n.dart';

class SubtlePulseIcon extends StatefulWidget {
  const SubtlePulseIcon({super.key});

  @override
  State<SubtlePulseIcon> createState() => _SubtlePulseIconState();
}

class _SubtlePulseIconState extends State<SubtlePulseIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class AudioPlayerBottomSheet extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;

  const AudioPlayerBottomSheet({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  ConsumerState<AudioPlayerBottomSheet> createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends ConsumerState<AudioPlayerBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerStateProvider.notifier).play(widget.filePath, widget.fileName);
    });
  }

  @override
  void dispose() {
    ref.read(audioPlayerStateProvider.notifier).stop();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerStateProvider);
    final isCurrent = playerState.filePath == widget.filePath;
    final isPlaying = isCurrent && playerState.isPlaying;
    final duration = isCurrent ? playerState.duration : Duration.zero;
    final position = isCurrent ? playerState.position : Duration.zero;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: DesignColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignSheetDragHandle(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.audiotrack_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.editor_audio_player_sheet_voice_recording,
                        style: DesignTypography.heading(
                          context,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.fileName,
                        style: DesignTypography.details(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                onChanged: (val) async {
                  await ref.read(audioPlayerStateProvider.notifier).seek(Duration(milliseconds: val.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: DesignTypography.metadata(context, fontSize: 11)),
                  Text(_formatDuration(duration), style: DesignTypography.metadata(context, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 28),
                  onPressed: () async {
                    await ref.read(audioPlayerStateProvider.notifier).seekRelative(const Duration(seconds: -10));
                  },
                ),
                const SizedBox(width: 16),
                TactileWrapper(
                  style: TactileFeedbackStyle.standard,
                  onTap: () async {
                    await ref.read(audioPlayerStateProvider.notifier).playOrToggle(widget.filePath, widget.fileName);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, size: 28),
                  onPressed: () async {
                    await ref.read(audioPlayerStateProvider.notifier).seekRelative(const Duration(seconds: 10));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}