import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../providers/audio_player_providers.dart';
import '../providers/audio_bookmark_providers.dart';
import '../providers/docked_audio_provider.dart';
import 'package:prism/l10n/l10n.dart';

/// Dockable audio evidence panel pinned as a sticky header bar at the top of the editor.
/// Provides playback, scrubbing, speed controls, 1-tap timestamp bookmarking, and undock.
class AudioEvidencePanel extends ConsumerStatefulWidget {
  final DockedAudio dockedAudio;
  final VoidCallback onUndock;
  final void Function(int timestampMs)? onAddBookmark;

  const AudioEvidencePanel({
    super.key,
    required this.dockedAudio,
    required this.onUndock,
    this.onAddBookmark,
  });

  @override
  ConsumerState<AudioEvidencePanel> createState() => _AudioEvidencePanelState();
}

class _AudioEvidencePanelState extends ConsumerState<AudioEvidencePanel> {
  static const List<double> _speedOptions = [0.8, 1.0, 1.5, 2.0];

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _cyclePlaybackSpeed(double currentSpeed) {
    HapticFeedback.selectionClick();
    final currentIndex = _speedOptions.indexOf(currentSpeed);
    final nextIndex = currentIndex == -1 ? 1 : (currentIndex + 1) % _speedOptions.length;
    final newSpeed = _speedOptions[nextIndex];
    ref.read(audioPlayerStateProvider.notifier).setPlaybackRate(newSpeed);
  }

  Future<void> _handleAddBookmark(int currentMs) async {
    HapticFeedback.mediumImpact();
    // 1. Insert timestamp tag into markdown buffer
    widget.onAddBookmark?.call(currentMs);

    // 2. Persist to database if noteId is available
    final noteId = widget.dockedAudio.noteId;
    final relPath = widget.dockedAudio.relativeFilePath ?? widget.dockedAudio.filePath;
    if (noteId != null && !noteId.startsWith('template:')) {
      final key = BookmarkKey(noteId: noteId, attachmentPath: relPath);
      await ref.read(audioBookmarkNotifierProvider(key).notifier).addBookmark(
            timestampMs: currentMs,
            annotation: 'Bookmark',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerStateProvider);
    final isCurrent = playerState.filePath == widget.dockedAudio.filePath;
    final isPlaying = isCurrent && playerState.isPlaying;
    final duration = isCurrent ? playerState.duration : Duration.zero;
    final position = isCurrent ? playerState.position : Duration.zero;
    final speed = playerState.playbackRate;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('audio_evidence_panel'),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        border: Border(
          bottom: BorderSide(
            color: DesignColors.border(context).withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Row: Icon + Title + Pin Toggle / Close Button ──
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dockedAudio.fileName,
                          style: DesignTypography.body(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DesignColors.text(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 11,
                            color: DesignColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Undock pin button
                  TactileWrapper(
                    key: const ValueKey('audio_evidence_undock'),
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onUndock();
                    },
                    child: Tooltip(
                      message: context.l10n.audio_evidence_undock_tooltip,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  TactileWrapper(
                    key: const ValueKey('audio_evidence_close'),
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onUndock();
                    },
                    child: Tooltip(
                      message: 'Close panel',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: DesignColors.border(context).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: DesignColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Scrubber Slider ──
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
                  thumbColor: colorScheme.primary,
                ),
                child: Slider(
                  value: position.inMilliseconds
                      .toDouble()
                      .clamp(0.0, duration.inMilliseconds.toDouble()),
                  max: duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (val) {
                    ref.read(audioPlayerStateProvider.notifier).seek(
                          Duration(milliseconds: val.toInt()),
                        );
                  },
                ),
              ),
              // ── Controls Row: Play/Pause + Replay/Forward + Speed + 1-Tap Bookmark ──
              Row(
                children: [
                  // Play/Pause button
                  TactileWrapper(
                    key: const ValueKey('audio_evidence_play_pause'),
                    style: TactileFeedbackStyle.highImpact,
                    onTap: () {
                      ref.read(audioPlayerStateProvider.notifier).playOrToggle(
                            widget.dockedAudio.filePath,
                            widget.dockedAudio.fileName,
                          );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Replay 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 20),
                    tooltip: 'Rewind 10s',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ref.read(audioPlayerStateProvider.notifier).seekRelative(
                            const Duration(seconds: -10),
                          );
                    },
                  ),
                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 20),
                    tooltip: 'Forward 10s',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ref.read(audioPlayerStateProvider.notifier).seekRelative(
                            const Duration(seconds: 10),
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Speed Control Chip
                  TactileWrapper(
                    key: const ValueKey('audio_evidence_speed_button'),
                    style: TactileFeedbackStyle.standard,
                    onTap: () => _cyclePlaybackSpeed(speed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DesignColors.border(context),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DesignColors.text(context),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 1-Tap Bookmark Action Button
                  TactileWrapper(
                    key: const ValueKey('audio_evidence_add_bookmark'),
                    style: TactileFeedbackStyle.highImpact,
                    onTap: () => _handleAddBookmark(position.inMilliseconds),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.tertiary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_add_outlined,
                            size: 16,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.editor_inline_audio_add_bookmark_title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
