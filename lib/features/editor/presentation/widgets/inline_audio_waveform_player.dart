import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../core/database/vault_providers.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../data/audio_bookmark_model.dart';
import '../providers/audio_player_providers.dart';
import '../providers/audio_bookmark_providers.dart';
import '../providers/docked_audio_provider.dart';
import '../utils/audio_waveform_peak_generator.dart';
import 'waveform_painter.dart';
import 'package:prism/l10n/l10n.dart';

class InlineAudioWaveformPlayer extends ConsumerStatefulWidget {
  final String filePath; // Relative path from the vault root
  final String fileName; // Label/Name of the attachment
  /// The note that owns this audio attachment — used for bookmark scoping.
  final String? noteId;

  const InlineAudioWaveformPlayer({
    super.key,
    required this.filePath,
    required this.fileName,
    this.noteId,
  });

  @override
  ConsumerState<InlineAudioWaveformPlayer> createState() =>
      _InlineAudioWaveformPlayerState();
}

class _InlineAudioWaveformPlayerState
    extends ConsumerState<InlineAudioWaveformPlayer> {
  String? _absolutePath;
  List<double> _peaks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolvePath();
  }

  @override
  void didUpdateWidget(InlineAudioWaveformPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      setState(() => _loading = true);
      _resolvePath();
    }
  }

  Future<void> _resolvePath() async {
    try {
      final vaultPath = await ref.read(activeVaultPathProvider.future);
      final absPath = p.join(vaultPath, widget.filePath);
      final file = File(absPath);
      if (await file.exists()) {
        final peaks = await Isolate.run(() async {
          final f = File(absPath);
          final seed = await AudioWaveformPeakGenerator.generateSeedFromFile(f);
          return AudioWaveformPeakGenerator.generatePeaks(seed: seed, count: 45);
        });
        if (mounted) {
          setState(() {
            _absolutePath = absPath;
            _peaks = peaks;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _absolutePath = null;
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error resolving audio path: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Loading')),
      );
    }

    final fullPath = _absolutePath;
    if (fullPath == null || !File(fullPath).existsSync()) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.editor_inline_audio_file_not_found(widget.fileName),
                style: DesignTypography.body(context, fontSize: 13, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    }

    return InlineWaveformWidget(
      filePath: fullPath,
      fileName: widget.fileName,
      peaks: _peaks,
      noteId: widget.noteId,
      relativeFilePath: widget.filePath,
    );
  }
}

class InlineWaveformWidget extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;
  final List<double> peaks;
  final String? noteId;
  final String? relativeFilePath;

  const InlineWaveformWidget({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.peaks,
    this.noteId,
    this.relativeFilePath,
  });

  @override
  ConsumerState<InlineWaveformWidget> createState() =>
      _InlineWaveformWidgetState();
}

class _InlineWaveformWidgetState extends ConsumerState<InlineWaveformWidget> {
  double? _dragProgress;
  Timer? _seekThrottleTimer;

  @override
  void dispose() {
    _seekThrottleTimer?.cancel();
    super.dispose();
  }

  BookmarkKey? get _bookmarkKey {
    final noteId = widget.noteId;
    final relPath = widget.relativeFilePath;
    if (noteId == null || relPath == null || noteId.startsWith('template:')) return null;
    return BookmarkKey(noteId: noteId, attachmentPath: relPath);
  }

  void _handlePanUpdate(
      DragUpdateDetails details, BoxConstraints constraints, AudioPlayerState playerState) {
    if (playerState.duration == Duration.zero) return;
    final double localX = details.localPosition.dx;
    final double progressFraction =
        (localX / constraints.maxWidth).clamp(0.0, 1.0);

    setState(() {
      _dragProgress = progressFraction;
    });

    if (_seekThrottleTimer == null) {
      final targetMs =
          (progressFraction * playerState.duration.inMilliseconds).toInt();
      ref.read(audioPlayerStateProvider.notifier).seek(
            Duration(milliseconds: targetMs),
          );
      _seekThrottleTimer = Timer(const Duration(milliseconds: 100), () {
        _seekThrottleTimer = null;
      });
    }
  }

  void _handlePanEnd(
      DragEndDetails details, AudioPlayerState playerState) {
    if (_dragProgress != null && playerState.duration > Duration.zero) {
      final targetMs =
          (_dragProgress! * playerState.duration.inMilliseconds).toInt();
      ref.read(audioPlayerStateProvider.notifier).seek(
            Duration(milliseconds: targetMs),
          );
    }
    setState(() {
      _dragProgress = null;
    });
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints,
      AudioPlayerState playerState, List<AudioBookmark> bookmarks) {
    if (playerState.duration == Duration.zero) return;
    final double localX = details.localPosition.dx;
    final double progressFraction =
        (localX / constraints.maxWidth).clamp(0.0, 1.0);

    // Check if tap is near a bookmark marker (within 10px)
    final tapX = localX;
    for (final bookmark in bookmarks) {
      final bookmarkX =
          (bookmark.timestampMs / playerState.duration.inMilliseconds) *
              constraints.maxWidth;
      if ((tapX - bookmarkX).abs() < 10) {
        ref.read(audioPlayerStateProvider.notifier).seek(
              Duration(milliseconds: bookmark.timestampMs),
            );
        return;
      }
    }

    final targetMs =
        (progressFraction * playerState.duration.inMilliseconds).toInt();
    ref.read(audioPlayerStateProvider.notifier).seek(
          Duration(milliseconds: targetMs),
        );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _showAddBookmarkDialog(
      BuildContext context, int currentMs, BookmarkKey key) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.editor_inline_audio_add_bookmark_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.editor_inline_audio_bookmark_at_time(_formatDuration(Duration(milliseconds: currentMs))),
              style: DesignTypography.metadata(context, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: context.l10n.editor_inline_audio_annotation_hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(audioBookmarkNotifierProvider(key).notifier).addBookmark(
            timestampMs: currentMs,
            annotation: controller.text.trim(),
          );
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerStateProvider);
    final isCurrent = playerState.filePath == widget.filePath;
    final isPlaying = isCurrent && playerState.isPlaying;

    final currentProgress = isCurrent ? playerState.progress : 0.0;
    final displayProgress = _dragProgress ?? currentProgress;

    final colorScheme = Theme.of(context).colorScheme;

    final key = _bookmarkKey;
    final bookmarkState =
        key != null ? ref.watch(audioBookmarkNotifierProvider(key)) : null;
    final bookmarks = bookmarkState?.bookmarks ?? const <AudioBookmark>[];

    // Calculate bookmark fractional positions for the waveform painter
    final List<double> bookmarkFractions = isCurrent &&
            playerState.duration > Duration.zero
        ? bookmarks
            .map((b) =>
                b.timestampMs / playerState.duration.inMilliseconds)
            .toList()
        : const [];

    final docked = ref.watch(dockedAudioProvider);
    final isDocked = docked != null &&
        (docked.filePath == widget.filePath ||
            (widget.relativeFilePath != null &&
                docked.relativeFilePath == widget.relativeFilePath));

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (isDocked) {
          ref.read(dockedAudioProvider.notifier).undock();
        } else {
          ref.read(dockedAudioProvider.notifier).dock(
                filePath: widget.filePath,
                fileName: widget.fileName,
                noteId: widget.noteId,
                relativeFilePath: widget.relativeFilePath,
              );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary.withValues(alpha: 0.3)
                : DesignColors.border(context),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: play/pause + title + time + pin + bookmark button ──
            Row(
              children: [
                IconButton(
                  icon: Icon(isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  onPressed: () {
                    ref
                        .read(audioPlayerStateProvider.notifier)
                        .playOrToggle(widget.filePath, widget.fileName);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        style: DesignTypography.body(context,
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isCurrent && playerState.duration > Duration.zero
                            ? '${_formatDuration(playerState.position)} / ${_formatDuration(playerState.duration)}'
                            : 'Voice Recording',
                        style: DesignTypography.metadata(context, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Pin to top / undock button
                IconButton(
                  key: const ValueKey('inline_audio_pin_button'),
                  icon: Icon(
                    isDocked ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 20,
                    color: isDocked
                        ? colorScheme.primary
                        : DesignColors.textSecondary(context),
                  ),
                  tooltip: isDocked ? 'Undock from top' : 'Pin to top',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (isDocked) {
                      ref.read(dockedAudioProvider.notifier).undock();
                    } else {
                      ref.read(dockedAudioProvider.notifier).dock(
                            filePath: widget.filePath,
                            fileName: widget.fileName,
                            noteId: widget.noteId,
                            relativeFilePath: widget.relativeFilePath,
                          );
                    }
                  },
                ),
                // Bookmark add button
                if (key != null)
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_add_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    tooltip:
                        context.l10n.editor_inline_audio_add_bookmark_tooltip,
                    onPressed: isCurrent
                        ? () => _showAddBookmarkDialog(
                              context,
                              playerState.position.inMilliseconds,
                              key,
                            )
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: 10),
          // ── Waveform with bookmark markers ──
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: isCurrent
                    ? (details) => _handleTapUp(
                          details, constraints, playerState, bookmarks)
                    : null,
                onHorizontalDragStart: isCurrent
                    ? (_) {
                        setState(() {
                          _dragProgress = currentProgress;
                        });
                      }
                    : null,
                onHorizontalDragUpdate: isCurrent
                    ? (details) =>
                        _handlePanUpdate(details, constraints, playerState)
                    : null,
                onHorizontalDragEnd: isCurrent
                    ? (details) => _handlePanEnd(details, playerState)
                    : null,
                onHorizontalDragCancel: isCurrent
                    ? () {
                        setState(() {
                          _dragProgress = null;
                        });
                      }
                    : null,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 40),
                  painter: WaveformPainter(
                    peaks: widget.peaks,
                    progress: displayProgress,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.primary.withValues(alpha: 0.24),
                    bookmarkPositions: bookmarkFractions,
                    bookmarkColor: colorScheme.tertiary,
                  ),
                ),
              );
            },
          ),
          // ── Error display ──
          if (bookmarkState?.error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.editor_inline_audio_database_error(bookmarkState!.error.toString()),
                      style: DesignTypography.body(context, fontSize: 11, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // ── Bookmark list ──
          if (bookmarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 4),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return _BookmarkListItem(
                  bookmark: bookmark,
                  onTap: () {
                    // If this file isn't loaded yet, play it first then seek
                    if (!isCurrent) {
                      ref
                          .read(audioPlayerStateProvider.notifier)
                          .playOrToggle(widget.filePath, widget.fileName);
                    }
                    ref.read(audioPlayerStateProvider.notifier).seek(
                          Duration(milliseconds: bookmark.timestampMs),
                        );
                  },
                  onDelete: key != null
                      ? () => ref
                          .read(audioBookmarkNotifierProvider(key).notifier)
                          .deleteBookmark(bookmark.id)
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    ),
  );
}
}

/// A single row in the bookmark list.
class _BookmarkListItem extends StatelessWidget {
  final AudioBookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _BookmarkListItem({
    required this.bookmark,
    required this.onTap,
    this.onDelete,
  });

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Text(
              _formatMs(bookmark.timestampMs),
              style: DesignTypography.metadata(context,
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (bookmark.annotationText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bookmark.annotationText,
                  style: DesignTypography.metadata(context, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Delete bookmark',
              ),
          ],
        ),
      ),
    );
  }
}