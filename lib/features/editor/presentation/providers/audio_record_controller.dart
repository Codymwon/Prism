import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/utils.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../domain/audio_recorder_service.dart';
import '../../data/audio_recorder_service_impl.dart';

part 'audio_record_controller.freezed.dart';
part 'audio_record_controller.g.dart';

// ─── AudioRecordState ─────────────────────────────────────────────────────────

/// Value class representing the state of the audio recording.
@freezed
class AudioRecordState with _$AudioRecordState {
  const factory AudioRecordState({
    @Default(false) bool isRecording,
    @Default(0) int durationSeconds,
  }) = _AudioRecordState;

  factory AudioRecordState.initial() => const AudioRecordState(
        isRecording: false,
        durationSeconds: 0,
      );
}

// ─── AudioRecordController ────────────────────────────────────────────────────

/// Controller managing audio note recording and timer.
@riverpod
class AudioRecordController extends _$AudioRecordController {
  late final AudioRecorderService _audioRecorder;
  String _audioPath = '';
  Timer? _timer;

  @override
  AudioRecordState build(String noteId) {
    _audioRecorder = ref.read(audioRecorderServiceProvider);
    ref.onDispose(() {
      _timer?.cancel();
      try {
        _audioRecorder.stop();
      } catch (_) {}

      if (_audioPath.isNotEmpty) {
        try {
          final file = File(_audioPath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Error deleting orphan audio on dispose: $e');
        }
      }
    });
    return AudioRecordState.initial();
  }

  Future<void> toggleRecording({
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
    String? vaultPath,
  }) async {
    if (state.isRecording) {
      await stopRecording(
        commit: true,
        textController: textController,
        focusNode: focusNode,
        onSave: onSave,
      );
      return;
    }

    try {
      final hasAudioPermission = await _audioRecorder.hasPermission();
      if (!hasAudioPermission) {
        throw Exception('Microphone permission is required.');
      }

      String? effectiveVaultPath = vaultPath;
      effectiveVaultPath ??= await ref.read(activeVaultPathProvider.future);

      final note = await ref.read(noteByIdProvider(noteId).future);
      if (note != null && note.filePath.isNotEmpty) {
        effectiveVaultPath = p.dirname(note.filePath);
      }

      final attachmentsDir = Directory(p.join(effectiveVaultPath!, 'attachments'));
      if (!attachmentsDir.existsSync()) {
        attachmentsDir.createSync(recursive: true);
      }

      final sessionId = generateId().substring(0, 8);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = p.join(attachmentsDir.path, 'audio_${timestamp}_$sessionId.m4a');
      _audioPath = audioPath;

      await _audioRecorder.start(audioPath);
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      });

      state = state.copyWith(isRecording: true, durationSeconds: 0);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopRecording({
    required bool commit,
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
  }) async {
    if (!state.isRecording) return;

    _timer?.cancel();
    state = state.copyWith(isRecording: false, durationSeconds: 0);

    final audioPath = await _audioRecorder.stop();
    final recordedPath = (audioPath != null && audioPath.isNotEmpty) ? audioPath : _audioPath;

    if (commit && recordedPath.isNotEmpty) {
      final filename = p.basename(recordedPath);

      final text = textController.text;
      final cursor = textController.selection.baseOffset;
      final before = cursor >= 0 ? text.substring(0, cursor) : text;
      final after = cursor >= 0 ? text.substring(cursor) : '';

      final audioLink = '\n\n[Audio Note](attachments/$filename)\n';
      textController.value = TextEditingValue(
        text: before + audioLink + after,
        selection: TextSelection.collapsed(
          offset: (cursor >= 0 ? cursor : text.length) + audioLink.length,
        ),
      );
    } else if (!commit) {
      final pathToDelete = recordedPath.isNotEmpty ? recordedPath : _audioPath;
      if (pathToDelete.isNotEmpty) {
        try {
          final file = File(pathToDelete);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Error deleting cancelled recording: $e');
        }
      }
    }

    _audioPath = '';
    focusNode.requestFocus();

    if (commit) {
      AnalyticsService.logEvent('record_audio');
      onSave();
    }
  }
}
