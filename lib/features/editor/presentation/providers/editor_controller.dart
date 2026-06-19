import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_repository.dart';
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
/// [DictationController] from the concrete `record` plugin.
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

// ─── SpeechToTextService ──────────────────────────────────────────────────────

/// Abstract seam for speech recognition, decoupling [DictationController] from
/// the concrete `speech_to_text` plugin.
abstract class SpeechToTextService {
  /// Initialises the speech recogniser.  Returns `true` if available.
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String error) onError,
  });

  /// Starts listening for speech.
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    Duration? listenFor,
    Duration? pauseFor,
  });

  /// Stops listening.
  Future<void> stop();

  /// Whether speech recognition is available on the current device.
  bool get isAvailable;

  /// Releases native resources.
  void dispose();
}

// ─── SpeechToTextServiceImpl ──────────────────────────────────────────────────

/// Production adapter wrapping the `speech_to_text` plugin [SpeechToText].
class SpeechToTextServiceImpl implements SpeechToTextService {
  final SpeechToText _stt = SpeechToText();

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String error) onError,
  }) {
    return _stt.initialize(
      onStatus: onStatus,
      onError: (e) => onError(e.toString()),
    );
  }

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) {
    return _stt.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: listenFor ?? const Duration(minutes: 10),
        pauseFor: pauseFor ?? const Duration(seconds: 15),
      ),
    );
  }

  @override
  Future<void> stop() => _stt.stop();

  @override
  bool get isAvailable => _stt.isAvailable;

  @override
  void dispose() {
    // SpeechToText has no explicit dispose – stop any active session.
    try {
      _stt.stop();
    } catch (_) {}
  }
}

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  final service = SpeechToTextServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

// ─── DictationState ───────────────────────────────────────────────────────────

/// Value class representing the state of the dictation.
@freezed
class DictationState with _$DictationState {
  const factory DictationState({
    @Default(false) bool isDictating,
    @Default('') String currentWords,
  }) = _DictationState;

  factory DictationState.initial() => const DictationState(
        isDictating: false,
        currentWords: '',
      );
}

// ─── DictationController ──────────────────────────────────────────────────────

/// Controller managing live text speech transcribing or audio-memo recording.
@riverpod
class DictationController extends _$DictationController {
  bool _mounted = true;

  late final AudioRecorderService _audioRecorder;
  late final SpeechToTextService _speechToText;

  bool _speechInitialized = false;
  int _dictationStartOffset = 0;
  String _dictationPreSpeechText = '';
  String _dictationAudioPath = '';
  String _dictationSessionId = '';
  int _speechSessionCount = 0;

  // Track active context fields for auto-restart on speech timeout
  TextEditingController? _activeTextController;
  FocusNode? _activeFocusNode;
  void Function()? _activeOnSave;


  @override
  DictationState build(String noteId) {
    _audioRecorder = ref.read(audioRecorderServiceProvider);
    _speechToText = ref.read(speechToTextServiceProvider);

    ref.onDispose(() {
      _mounted = false;
      try {
        _speechToText.stop();
      } catch (_) {}

      if (state.isDictating && _dictationAudioPath.isNotEmpty) {
        try {
          final file = File(_dictationAudioPath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Error deleting orphan audio on dispose: $e');
        }
      }

      _audioRecorder.dispose();
    });
    return DictationState.initial();
  }

  Future<void> toggleDictation({
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
    bool keepVoice = false,
    String? vaultPath,
  }) async {
    if (state.isDictating) {
      await stopDictation(
        commit: true,
        textController: textController,
        focusNode: focusNode,
        onSave: onSave,
        keepVoice: keepVoice,
      );
      return;
    }

    // If using provider, read keepVoice from settings
    final effectiveKeepVoice = keepVoice || (ref.read(keepVoiceRecordingsProvider).valueOrNull ?? false);

    try {
      if (!effectiveKeepVoice) {
        if (!_speechInitialized) {
          final available = await _speechToText.initialize(
            onStatus: (status) {
              if (status == 'notListening' && state.isDictating) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (state.isDictating && _mounted) {
                    final txtCtrl = _activeTextController;
                    final fn = _activeFocusNode;
                    final os = _activeOnSave;
                    if (txtCtrl != null && fn != null && os != null) {
                      _startListening(
                        isRestart: true,
                        textController: txtCtrl,
                        focusNode: fn,
                        onSave: os,
                        keepVoice: effectiveKeepVoice,
                        vaultPath: vaultPath,
                      );
                    }
                  }
                });
              }
            },
            onError: (error) {
              debugPrint('Speech error: $error');
            },
          );
          if (!available) {
            throw Exception('Speech recognition is not available on this device.');
          }
          _speechInitialized = true;
        }
      }

      final hasAudioPermission = await _audioRecorder.hasPermission();
      if (hasAudioPermission) {
        _startListening(
          isRestart: false,
          textController: textController,
          focusNode: focusNode,
          onSave: onSave,
          keepVoice: effectiveKeepVoice,
          vaultPath: vaultPath,
        );
      } else {
        throw Exception('Microphone permission is required.');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _startListening({
    required bool isRestart,
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
    required bool keepVoice,
    String? vaultPath,
  }) async {
    _activeTextController = textController;
    _activeFocusNode = focusNode;
    _activeOnSave = onSave;

    _speechSessionCount++;
    final currentSession = _speechSessionCount;

    if (!isRestart) {
      final selection = textController.selection;
      _dictationStartOffset = selection.isValid ? selection.baseOffset : textController.text.length;
      _dictationPreSpeechText = textController.text;
      state = state.copyWith(isDictating: true, currentWords: '');
    } else {
      _dictationStartOffset = (_dictationStartOffset + state.currentWords.length).clamp(0, textController.text.length);
      _dictationPreSpeechText = textController.text;
      state = state.copyWith(isDictating: true, currentWords: '');
    }

    if (keepVoice) {
      if (!isRestart) {
        try {
          final String resolvedPath = await ref.read(activeVaultPathProvider.future);
          final effectiveVaultPath = vaultPath ?? resolvedPath;
          final attachmentsDir = Directory(p.join(effectiveVaultPath, 'attachments'));
          if (!await attachmentsDir.exists()) {
            await attachmentsDir.create(recursive: true);
          }

          _dictationSessionId = generateId().substring(0, 8);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final audioPath = p.join(attachmentsDir.path, 'audio_${timestamp}_$_dictationSessionId.m4a');
          _dictationAudioPath = audioPath;

          await _audioRecorder.start(audioPath);
        } catch (e) {
          debugPrint('Audio recording error: $e');
        }
      }
    } else {
      await _speechToText.listen(
        onResult: (words, isFinal) {
          if (!_mounted || !state.isDictating || _speechSessionCount != currentSession) return;

          String newWords = words;

          if (newWords.isEmpty && state.currentWords.isNotEmpty) {
            _dictationStartOffset = (_dictationStartOffset + state.currentWords.length).clamp(0, textController.text.length);
            _dictationPreSpeechText = textController.text;
            state = state.copyWith(currentWords: '');
          }

          final before = _dictationPreSpeechText.substring(0, _dictationStartOffset);
          final after = _dictationPreSpeechText.substring(_dictationStartOffset);

          if (_dictationStartOffset > 0 &&
              before.isNotEmpty &&
              !before.endsWith(' ') &&
              !before.endsWith('\n') &&
              newWords.isNotEmpty &&
              !newWords.startsWith(' ')) {
            newWords = ' $newWords';
          }

          state = state.copyWith(currentWords: newWords);

          textController.value = TextEditingValue(
            text: before + newWords + after,
            selection: TextSelection.collapsed(offset: _dictationStartOffset + newWords.length),
          );
        },
      );
    }
  }

  Future<void> stopDictation({
    required bool commit,
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
    bool keepVoice = false,
  }) async {
    if (!state.isDictating) return;

    state = state.copyWith(isDictating: false);

    final effectiveKeepVoice = keepVoice || (ref.read(keepVoiceRecordingsProvider).valueOrNull ?? false);

    if (!effectiveKeepVoice) {
      await _speechToText.stop();
    }
    final audioPath = await _audioRecorder.stop();

    if (!commit) {
      textController.value = TextEditingValue(
        text: _dictationPreSpeechText,
        selection: TextSelection.collapsed(offset: _dictationStartOffset),
      );

      if (_dictationAudioPath.isNotEmpty) {
        final file = File(_dictationAudioPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } else {
      if (effectiveKeepVoice && audioPath != null && _dictationAudioPath.isNotEmpty) {
        final filename = p.basename(_dictationAudioPath);

        final text = textController.text;
        final cursor = textController.selection.baseOffset;
        final before = text.substring(0, cursor);
        final after = text.substring(cursor);

        final audioLink = '\n\n[Audio Note](attachments/$filename)\n';
        textController.value = TextEditingValue(
          text: before + audioLink + after,
          selection: TextSelection.collapsed(offset: cursor + audioLink.length),
        );
      }
    }

    _dictationAudioPath = '';
    state = state.copyWith(currentWords: '');
    focusNode.requestFocus();

    if (commit) {
      onSave();
    }
  }


}
