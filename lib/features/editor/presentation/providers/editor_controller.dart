import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';

import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Value class representing the state of the editor.
class EditorState {
  final bool isLoaded;
  final bool isSaving;
  final bool showWikilinkPopup;
  final String wikilinkQuery;
  final String loadedTitle;
  final String loadedBody;
  final String? dailyDate;
  final String lastSaved;

  const EditorState({
    required this.isLoaded,
    required this.isSaving,
    required this.showWikilinkPopup,
    required this.wikilinkQuery,
    required this.loadedTitle,
    required this.loadedBody,
    this.dailyDate,
    required this.lastSaved,
  });

  factory EditorState.initial() {
    return const EditorState(
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

  EditorState copyWith({
    bool? isLoaded,
    bool? isSaving,
    bool? showWikilinkPopup,
    String? wikilinkQuery,
    String? loadedTitle,
    String? loadedBody,
    String? dailyDate,
    String? lastSaved,
  }) {
    return EditorState(
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      showWikilinkPopup: showWikilinkPopup ?? this.showWikilinkPopup,
      wikilinkQuery: wikilinkQuery ?? this.wikilinkQuery,
      loadedTitle: loadedTitle ?? this.loadedTitle,
      loadedBody: loadedBody ?? this.loadedBody,
      dailyDate: dailyDate ?? this.dailyDate,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}

/// Controller managing the editor state, autosaves, and wikilink autocompletion.
class EditorController extends StateNotifier<EditorState> {
  final Ref ref;
  final String noteId;
  Timer? _saveTimer;

  EditorController(this.ref, this.noteId) : super(EditorState.initial());

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

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

}

/// Riverpod StateNotifierProvider for EditorController
final editorControllerProvider = StateNotifierProvider.autoDispose
    .family<EditorController, EditorState, String>((ref, noteId) {
  return EditorController(ref, noteId);
});


/// Value class representing the state of the dictation.
class DictationState {
  final bool isDictating;
  final String currentWords;

  const DictationState({
    required this.isDictating,
    required this.currentWords,
  });

  factory DictationState.initial() {
    return const DictationState(
      isDictating: false,
      currentWords: '',
    );
  }

  DictationState copyWith({
    bool? isDictating,
    String? currentWords,
  }) {
    return DictationState(
      isDictating: isDictating ?? this.isDictating,
      currentWords: currentWords ?? this.currentWords,
    );
  }
}

/// Controller managing live text speech transcribing or audio-memo recording.
class DictationController extends StateNotifier<DictationState> {
  final Ref ref;
  final String noteId;

  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
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

  DictationController(this.ref, this.noteId) : super(DictationState.initial());

  Future<void> toggleDictation({
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
  }) async {
    if (state.isDictating) {
      await stopDictation(commit: true, textController: textController, focusNode: focusNode, onSave: onSave);
      return;
    }

    final keepVoice = ref.read(keepVoiceRecordingsProvider).valueOrNull ?? false;

    try {
      if (!keepVoice) {
        if (!_speechInitialized) {
          bool available = await _speechToText.initialize(
            onStatus: (status) {
              if (status == 'notListening' && state.isDictating) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (state.isDictating && mounted) {
                    final txtCtrl = _activeTextController;
                    final fn = _activeFocusNode;
                    final os = _activeOnSave;
                    if (txtCtrl != null && fn != null && os != null) {
                      _startListening(
                        isRestart: true,
                        textController: txtCtrl,
                        focusNode: fn,
                        onSave: os,
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
  }) async {
    _activeTextController = textController;
    _activeFocusNode = focusNode;
    _activeOnSave = onSave;

    final keepVoice = ref.read(keepVoiceRecordingsProvider).valueOrNull ?? false;

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
          final vaultPath = await getVaultPath();
          final attachmentsDir = Directory(p.join(vaultPath, 'attachments'));
          if (!await attachmentsDir.exists()) {
            await attachmentsDir.create(recursive: true);
          }

          _dictationSessionId = generateId().substring(0, 8);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final audioPath = p.join(attachmentsDir.path, 'audio_${timestamp}_$_dictationSessionId.m4a');
          _dictationAudioPath = audioPath;

          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              sampleRate: 16000,
              numChannels: 1,
              bitRate: 32000,
            ),
            path: audioPath,
          );
        } catch (e) {
          debugPrint('Audio recording error: $e');
        }
      }
    } else {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted || !state.isDictating || _speechSessionCount != currentSession) return;

          String newWords = result.recognizedWords;

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
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 15),
        ),
      );
    }
  }

  Future<void> stopDictation({
    required bool commit,
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function() onSave,
  }) async {
    if (!state.isDictating) return;

    state = state.copyWith(isDictating: false);

    final keepVoice = ref.read(keepVoiceRecordingsProvider).valueOrNull ?? false;

    if (!keepVoice) {
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
      if (keepVoice && audioPath != null && _dictationAudioPath.isNotEmpty) {
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

  @override
  void dispose() {
    try {
      _speechToText.stop();
    } catch (_) {}
    _audioRecorder.dispose();
    super.dispose();
  }
}

/// Riverpod StateNotifierProvider for DictationController
final dictationControllerProvider = StateNotifierProvider.autoDispose
    .family<DictationController, DictationState, String>((ref, noteId) {
  return DictationController(ref, noteId);
});
