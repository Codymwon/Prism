import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../core/database/vault_providers.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/utils/utils.dart';
import '../../features/editor/data/audio_recorder_service_impl.dart';
import '../../features/editor/presentation/widgets/audio_player_bottom_sheet.dart';
import '../../features/folders/data/folder_repository.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/notes/data/note_model.dart';
import '../../features/notes/data/note_repository.dart';
import '../design_system/design_system.dart';
import 'app_shell.dart';
import 'island_menu.dart';
import 'prism_toast.dart';
import 'tactile_wrapper.dart';
import 'package:prism/l10n/l10n.dart';

/// Active presentation mode inside the Quick Capture Deck.
enum QuickCaptureMode {
  actions,
  recording,
}

/// State model for the Global Quick Capture Action Deck.
class QuickCaptureState {
  final bool isOpen;
  final QuickCaptureMode mode;
  final int durationSeconds;
  final String? audioPath;

  const QuickCaptureState({
    this.isOpen = false,
    this.mode = QuickCaptureMode.actions,
    this.durationSeconds = 0,
    this.audioPath,
  });

  QuickCaptureState copyWith({
    bool? isOpen,
    QuickCaptureMode? mode,
    int? durationSeconds,
    String? audioPath,
  }) {
    return QuickCaptureState(
      isOpen: isOpen ?? this.isOpen,
      mode: mode ?? this.mode,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}

/// Riverpod notifier coordinating Quick Capture lifecycle, voice memo hardware recording,
/// and note creation across the application.
class QuickCaptureNotifier extends Notifier<QuickCaptureState> {
  Timer? _timer;

  @override
  QuickCaptureState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const QuickCaptureState();
  }

  void open() {
    _timer?.cancel();
    state = const QuickCaptureState(
      isOpen: true,
      mode: QuickCaptureMode.actions,
    );
  }

  void dismiss() {
    _timer?.cancel();
    if (state.mode == QuickCaptureMode.recording && state.audioPath != null) {
      _discardRecording();
    }
    state = const QuickCaptureState(isOpen: false);
  }

  Future<void> startRecording(BuildContext context) async {
    // 1. Consent Guard check
    final prefs = ref.read(sharedPreferencesProvider);
    final hasAccepted =
        prefs.getBool('has_accepted_audio_recording_notice') ?? false;

    if (!hasAccepted) {
      final agreed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: DesignColors.surface(dialogContext),
            title: Text(
              dialogContext.l10n.editor_audio_wiretap_notice_title,
              style: DesignTypography.heading(dialogContext,
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: Text(
              dialogContext.l10n.editor_audio_wiretap_notice_body,
              style: DesignTypography.body(dialogContext,
                  fontSize: 14,
                  color: DesignColors.textSecondary(dialogContext)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  dialogContext.l10n.editor_audio_wiretap_notice_cancel,
                  style: TextStyle(
                      color: DesignColors.textSecondary(dialogContext)),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: DesignColors.primary(dialogContext),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  dialogContext.l10n.editor_audio_wiretap_notice_agree,
                ),
              ),
            ],
          );
        },
      );

      if (agreed != true) {
        return;
      }
      await prefs.setBool('has_accepted_audio_recording_notice', true);
    }

    // 2. Hardware recording setup
    try {
      final recorder = ref.read(audioRecorderServiceProvider);
      final hasPerm = await recorder.hasPermission();
      if (!hasPerm) {
        if (context.mounted) {
          PrismToast.show(context, 'Microphone permission is required.');
        }
        return;
      }

      final vaultPath = await ref.read(activeVaultPathProvider.future);
      final attachmentsDir = Directory(p.join(vaultPath, 'attachments'));
      if (!attachmentsDir.existsSync()) {
        attachmentsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sessionId = generateId().substring(0, 8);
      final audioPath =
          p.join(attachmentsDir.path, 'audio_${timestamp}_$sessionId.m4a');

      await recorder.start(audioPath);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      });

      state = QuickCaptureState(
        isOpen: true,
        mode: QuickCaptureMode.recording,
        durationSeconds: 0,
        audioPath: audioPath,
      );
    } catch (e) {
      if (context.mounted) {
        PrismToast.show(context, 'Error starting recording: $e');
      }
    }
  }

  Future<void> cancelRecording() async {
    _timer?.cancel();
    await _discardRecording();
    state = const QuickCaptureState(isOpen: false);
  }

  Future<void> _discardRecording() async {
    final path = state.audioPath;
    final recorder = ref.read(audioRecorderServiceProvider);
    try {
      await recorder.stop();
    } catch (_) {}
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  Future<Note?> commitRecording(BuildContext context) async {
    _timer?.cancel();
    final path = state.audioPath;
    final recorder = ref.read(audioRecorderServiceProvider);
    String? recordedPath;
    try {
      recordedPath = await recorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }

    recordedPath ??= path;
    if (recordedPath == null || !File(recordedPath).existsSync()) {
      state = const QuickCaptureState(isOpen: false);
      return null;
    }

    final fileName = p.basename(recordedPath);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final title = 'Voice Memo — $dateStr';
    final content = '\n\n[Audio Note](attachments/$fileName)\n';

    final repo = ref.read(noteRepositoryProvider);
    // Uncategorized inbox note (CARD-18): no folder associated
    final note = await repo.createNote(
      title: title,
      initialContent: content,
    );

    state = const QuickCaptureState(isOpen: false);

    if (context.mounted) {
      PrismToast.show(context, context.l10n.quick_capture_saved_toast);
    }

    return note;
  }

  Future<void> createBlankNote(BuildContext context) async {
    dismiss();
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.createNote();

    final selectedFolderId = ref.read(selectedFolderIdProvider);
    if (selectedFolderId != null) {
      final folderRepo = ref.read(folderRepositoryProvider);
      await folderRepo.addNoteToFolder(note.id, selectedFolderId);
    }

    if (context.mounted) {
      try {
        context.push('/editor/${note.id}?new=true');
      } catch (_) {}
    }
  }
}

final quickCaptureNotifierProvider =
    NotifierProvider<QuickCaptureNotifier, QuickCaptureState>(
  QuickCaptureNotifier.new,
);

/// Entrypoint to invoke the Quick Capture Deck.
/// Blooms directly into AppShell Dynamic Island or falls back to an adaptive bottom sheet.
class QuickCapture {
  static void show(BuildContext context) {
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    final hasAppShell =
        context.findAncestorWidgetOfExactType<AppShell>() != null ||
        context.widget is AppShell;

    if (container != null && hasAppShell) {
      // Mutual exclusivity: dismiss toast & island menu before quick capture bloom
      container.read(islandToastNotifierProvider.notifier).dismiss();
      container.read(islandMenuNotifierProvider.notifier).dismiss();
      container.read(quickCaptureNotifierProvider.notifier).open();
      return;
    }

    // Fallback modal bottom sheet on non-AppShell screens
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickCaptureModalFallback(),
    );
  }
}

/// Fallback modal bottom sheet rendering Quick Capture outside AppShell.
class QuickCaptureModalFallback extends ConsumerWidget {
  const QuickCaptureModalFallback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickCaptureNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignSpacing.borderRadiusLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DesignSheetDragHandle(),
              if (state.mode == QuickCaptureMode.recording)
                QuickCaptureRecordingDeck(
                  state: state,
                  onCancel: () {
                    ref
                        .read(quickCaptureNotifierProvider.notifier)
                        .cancelRecording();
                    Navigator.pop(context);
                  },
                  onCommit: () async {
                    await ref
                        .read(quickCaptureNotifierProvider.notifier)
                        .commitRecording(context);
                    if (context.mounted) Navigator.pop(context);
                  },
                )
              else
                QuickCaptureActionsDeck(
                  onRecordVoiceMemo: () {
                    ref
                        .read(quickCaptureNotifierProvider.notifier)
                        .startRecording(context);
                  },
                  onBlankDocument: () {
                    Navigator.pop(context);
                    ref
                        .read(quickCaptureNotifierProvider.notifier)
                        .createBlankNote(context);
                  },
                  onClose: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upper deck UI displaying Quick Capture actions (Record Voice Memo & Blank Document).
class QuickCaptureActionsDeck extends StatelessWidget {
  final VoidCallback onRecordVoiceMemo;
  final VoidCallback onBlankDocument;
  final VoidCallback onClose;

  const QuickCaptureActionsDeck({
    super.key,
    required this.onRecordVoiceMemo,
    required this.onBlankDocument,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('quick_capture_actions_deck'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Icon + Title + Close Button
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 13,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.quick_capture_title,
                  style: DesignTypography.body(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DesignColors.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                key: const ValueKey('quick_capture_close'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onClose();
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: DesignColors.border(context).withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: DesignColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Actions Row
          Row(
            children: [
              Expanded(
                child: TactileWrapper(
                  key: const ValueKey('quick_capture_record_voice_memo'),
                  style: TactileFeedbackStyle.highImpact,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRecordVoiceMemo();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: DesignColors.surfaceVariant(context)
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            DesignColors.border(context).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.quick_capture_record_voice_memo,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DesignColors.text(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Live waveform + Inbox',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: DesignColors.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TactileWrapper(
                  key: const ValueKey('quick_capture_blank_document'),
                  style: TactileFeedbackStyle.highImpact,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onBlankDocument();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: DesignColors.surfaceVariant(context)
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            DesignColors.border(context).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.quick_capture_blank_document,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DesignColors.text(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'New empty note',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: DesignColors.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Deck rendering live recording timer, animated audio waveform, cancel & commit actions.
class QuickCaptureRecordingDeck extends StatelessWidget {
  final QuickCaptureState state;
  final VoidCallback onCancel;
  final VoidCallback onCommit;

  const QuickCaptureRecordingDeck({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onCommit,
  });

  String _formatSeconds(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('quick_capture_recording_deck'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Pulsing dot + duration timer + cancel button
          Row(
            children: [
              const SubtlePulseIcon(),
              const SizedBox(width: 8),
              Text(
                _formatSeconds(state.durationSeconds),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recording voice memo…',
                  style: DesignTypography.body(
                    context,
                    fontSize: 11,
                    color: DesignColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Discard / Cancel button
              TactileWrapper(
                key: const ValueKey('quick_capture_cancel'),
                style: TactileFeedbackStyle.standard,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCancel();
                },
                child: Tooltip(
                  message: 'Discard recording',
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Waveform & Commit Button Row
          Row(
            children: [
              // Animated Waveform Bars
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: _QuickCaptureAnimatedWaveform(
                    tick: state.durationSeconds,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save / Stop Button
              TactileWrapper(
                key: const ValueKey('quick_capture_commit'),
                style: TactileFeedbackStyle.highImpact,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onCommit();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
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
    );
  }
}

/// Simulated live animated audio waveform bars during quick capture recording.
class _QuickCaptureAnimatedWaveform extends StatelessWidget {
  final int tick;

  const _QuickCaptureAnimatedWaveform({required this.tick});

  static const List<double> _baseHeights = [
    0.35, 0.65, 0.90, 0.45, 0.70, 0.30, 0.85, 0.50,
    0.75, 0.40, 0.95, 0.60, 0.35, 0.80, 0.55, 0.70,
    0.40, 0.85, 0.60, 0.30, 0.90, 0.50, 0.75, 0.45,
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barCount = _baseHeights.length;
        final totalWidth = constraints.maxWidth;
        final barWidth = (totalWidth / (barCount * 1.6)).clamp(2.0, 4.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            // Modulate heights slightly with tick for continuous organic pulsing
            final shift = (i + tick) % barCount;
            final heightFactor = _baseHeights[shift];
            return Container(
              width: barWidth,
              height: (constraints.maxHeight * heightFactor).clamp(4.0, constraints.maxHeight),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.6 + 0.35 * heightFactor),
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            );
          }),
        );
      },
    );
  }
}
