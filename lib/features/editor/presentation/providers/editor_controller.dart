import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

part 'editor_controller.freezed.dart';
part 'editor_controller.g.dart';

// ─── EditorState ──────────────────────────────────────────────────────────────

/// Value class representing the state of the editor.
@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    @Default(false) bool isLoaded,
    @Default(false) bool isSaving,
    @Default(false) bool showWikilinkPopup,
    @Default('') String wikilinkQuery,
    @Default('') String loadedTitle,
    @Default('') String loadedBody,
    String? dailyDate,
    @Default('') String lastSaved,
  }) = _EditorState;

  factory EditorState.initial() => const EditorState(
        isLoaded: false,
        isSaving: false,
        showWikilinkPopup: false,
        wikilinkQuery: '',
        loadedTitle: '',
        loadedBody: '',
        dailyDate: null,
        lastSaved: '',
      );
}

// ─── EditorController ─────────────────────────────────────────────────────────

/// Controller managing the editor state, autosaves, and wikilink autocompletion.
@riverpod
class EditorController extends _$EditorController {
  Timer? _saveTimer;

  @override
  EditorState build(String noteId) {
    ref.onDispose(() {
      _saveTimer?.cancel();
    });
    return EditorState.initial();
  }

  Future<EditorState?> loadNote({required bool isNew, String? defaultDailyDate}) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNoteById(noteId);
    if (note == null) return null;

    final dateStr = note.dailyDate ?? defaultDailyDate;

    String content = '';
    try {
      content = await repo.readNoteContent(noteId);
    } catch (_) {
      content = '---\ntitle: "${note.title}"\n---\n\n';
    }

    final parsedTitle = extractFrontmatterValue(content, 'title') ?? note.title;
    var parsedBody = stripFrontmatter(content);

    // Strip the H1 header from the body if the note doesn't have frontmatter (legacy migration)
    final hasFrontmatter = content.trimLeft().startsWith('---\n') || content.trimLeft().startsWith('---\r\n');
    if (!hasFrontmatter) {
      final lines = parsedBody.split('\n');
      int h1Index = -1;
      for (int i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        if (trimmed.startsWith('# ')) {
          final cleanText = trimmed.substring(2).trim();
          if (cleanText == parsedTitle) {
            h1Index = i;
            break;
          }
        }
      }
      if (h1Index != -1) {
        lines.removeAt(h1Index);
        while (lines.isNotEmpty && lines.first.trim().isEmpty) {
          lines.removeAt(0);
        }
        parsedBody = lines.join('\n');
      }
    }

    state = state.copyWith(
      isLoaded: true,
      loadedTitle: parsedTitle,
      loadedBody: parsedBody,
      lastSaved: content,
      dailyDate: dateStr,
    );

    return state;
  }

  void onTextChanged(String title, String body, TextSelection selection, bool isDictating) {
    _detectWikilink(body, selection);

    _saveTimer?.cancel();
    if (!isDictating) {
      _saveTimer = Timer(const Duration(milliseconds: 500), () => save(title, body));
    }
  }

  void _detectWikilink(String text, TextSelection selection) {
    if (!selection.isValid) return;

    final cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > text.length) {
      if (state.showWikilinkPopup) {
        state = state.copyWith(showWikilinkPopup: false);
      }
      return;
    }

    final before = text.substring(0, cursor);
    final openBracket = before.lastIndexOf('[[');

    if (openBracket != -1 && !before.substring(openBracket).contains(']]')) {
      final query = before.substring(openBracket + 2);
      if (query.isNotEmpty) {
        state = state.copyWith(
          showWikilinkPopup: true,
          wikilinkQuery: query,
        );
        return;
      }
    }

    if (state.showWikilinkPopup) {
      state = state.copyWith(showWikilinkPopup: false);
    }
  }

  Future<void> save(String title, String body) async {
    if (title == state.loadedTitle && body == state.loadedBody) return;

    final cleanTitle = title.trim().isEmpty ? 'Untitled' : title.trim();
    final dateStr = state.dailyDate;

    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('title: "$cleanTitle"');
    if (dateStr != null) {
      buffer.writeln('date: $dateStr');
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(body);

    final content = buffer.toString();
    if (content == state.lastSaved) return;

    state = state.copyWith(isSaving: true);
    final repo = ref.read(noteRepositoryProvider);
    await repo.saveNote(noteId, content);

    state = state.copyWith(
      isSaving: false,
      lastSaved: content,
      loadedTitle: title,
      loadedBody: body,
    );
  }

  Future<void> saveIfNeeded(String title, String body) async {
    _saveTimer?.cancel();
    if (title != state.loadedTitle || body != state.loadedBody) {
      await save(title, body);
    }
  }

  TextEditingValue? insertWikilink(String noteTitle, String currentText, TextSelection selection) {
    if (!selection.isValid) {
      state = state.copyWith(showWikilinkPopup: false);
      return null;
    }
    final before = currentText.substring(0, selection.baseOffset);
    final openBracket = before.lastIndexOf('[[');

    if (openBracket != -1) {
      final after = currentText.substring(selection.baseOffset);
      final newText = '${currentText.substring(0, openBracket)}[[$noteTitle]]$after';
      final newCursor = openBracket + noteTitle.length + 4;
      state = state.copyWith(showWikilinkPopup: false);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    }
    state = state.copyWith(showWikilinkPopup: false);
    return null;
  }

  void dismissWikilinkPopup() {
    if (state.showWikilinkPopup) {
      state = state.copyWith(showWikilinkPopup: false);
    }
  }


}


// ─── AudioRecorderService ─────────────────────────────────────────────────────

/// Abstract seam for microphone permission and audio recording, decoupling
/// [AudioRecordController] from the concrete `record` plugin.
abstract class AudioRecorderService {
  /// Returns `true` if the app has microphone permission.
  Future<bool> hasPermission();

  /// Starts recording to [path].
  Future<void> start(String path);

  /// Stops recording and returns the file path of the recorded audio, if any.
  Future<String?> stop();

  /// Returns `true` if a recording is in progress.
  Future<bool> isRecording();

  /// Releases native resources.
  void dispose();
}

// ─── AudioRecorderServiceImpl ─────────────────────────────────────────────────

/// Production adapter wrapping the `record` plugin [AudioRecorder].
class AudioRecorderServiceImpl implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) {
    return _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 32000,
      ),
      path: path,
    );
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<bool> isRecording() => _recorder.isRecording();

  @override
  void dispose() => _recorder.dispose();
}

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

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
      if (effectiveVaultPath == null) {
        effectiveVaultPath = await ref.read(activeVaultPathProvider.future);
      }

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

    if (commit && audioPath != null && _audioPath.isNotEmpty) {
      final filename = p.basename(_audioPath);

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
    } else {
      if (_audioPath.isNotEmpty) {
        try {
          final file = File(_audioPath);
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
      onSave();
    }
  }
}
