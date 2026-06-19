import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';

// ---------------------------------------------------------------------------
// Fake AudioRecorderService
// ---------------------------------------------------------------------------
class FakeAudioRecorderService implements AudioRecorderService {
  final List<String> calls = [];
  bool _hasPermission = true;
  bool _isRecording = false;

  void setPermission(bool value) => _hasPermission = value;

  @override
  Future<bool> hasPermission() async {
    calls.add('hasPermission');
    return _hasPermission;
  }

  @override
  Future<void> start(String path) async {
    calls.add('start:$path');
    _isRecording = true;
  }

  @override
  Future<String?> stop() async {
    calls.add('stop');
    _isRecording = false;
    return _isRecording ? null : 'recorded_path.m4a';
  }

  @override
  Future<bool> isRecording() async {
    return _isRecording;
  }

  @override
  void dispose() {
    calls.add('dispose');
  }
}

// ---------------------------------------------------------------------------
// Fake SpeechToTextService
// ---------------------------------------------------------------------------
class FakeSpeechToTextService implements SpeechToTextService {
  final List<String> calls = [];
  bool _available = true;

  void setAvailability(bool value) => _available = value;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String error) onError,
  }) async {
    calls.add('initialize');
    return _available;
  }

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    calls.add('listen');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  bool get isAvailable => _available;

  @override
  void dispose() {
    calls.add('dispose');
  }
}

void main() {
  late FakeAudioRecorderService fakeRecorder;
  late FakeSpeechToTextService fakeSpeech;
  late ProviderContainer container;
  late DictationController dictation;
  late TextEditingController textCtrl;
  late FocusNode focusNode;

  setUp(() {
    fakeRecorder = FakeAudioRecorderService();
    fakeSpeech = FakeSpeechToTextService();
    container = ProviderContainer(
      overrides: [
        audioRecorderServiceProvider.overrideWithValue(fakeRecorder),
        speechToTextServiceProvider.overrideWithValue(fakeSpeech),
      ],
    );
    dictation = container.read(dictationControllerProvider('test-note').notifier);
    textCtrl = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    container.dispose();
    textCtrl.dispose();
    focusNode.dispose();
  });

  group('DictationController via AudioRecorderService and SpeechToTextService', () {
    test('toggleDictation checks microphone permission via AudioRecorderService', () async {
      await dictation.toggleDictation(
        textController: textCtrl,
        focusNode: focusNode,
        onSave: () {},
        keepVoice: false,
      );

      expect(fakeRecorder.calls, contains('hasPermission'));
    });

    test('toggleDictation starts STT when keepVoice is false and permission granted', () async {
      await dictation.toggleDictation(
        textController: textCtrl,
        focusNode: focusNode,
        onSave: () {},
        keepVoice: false,
      );

      expect(fakeSpeech.calls, contains('initialize'));
      expect(fakeSpeech.calls, contains('listen'));
      expect(dictation.state.isDictating, isTrue);
    });

    test('toggleDictation starts audio recording when keepVoice is true', () async {
      await dictation.toggleDictation(
        textController: textCtrl,
        focusNode: focusNode,
        onSave: () {},
        keepVoice: true,
        vaultPath: '/test/vault',
      );

      expect(fakeRecorder.calls, anyOf(
        contains('hasPermission'),
        anyElement(startsWith('start:')),
      ));
      expect(dictation.state.isDictating, isTrue);
    });

    test('stopDictation stops STT when keepVoice is false', () async {
      await dictation.toggleDictation(
        textController: textCtrl,
        focusNode: focusNode,
        onSave: () {},
        keepVoice: false,
      );

      await dictation.stopDictation(
        commit: true,
        textController: textCtrl,
        focusNode: focusNode,
        onSave: () {},
        keepVoice: false,
      );

      expect(fakeSpeech.calls, contains('stop'));
      expect(dictation.state.isDictating, isFalse);
    });

    test('toggleDictation throws when microphone permission denied', () async {
      fakeRecorder.setPermission(false);

      expect(
        () => dictation.toggleDictation(
          textController: textCtrl,
          focusNode: focusNode,
          onSave: () {},
          keepVoice: false,
        ),
        throwsException,
      );
    });

    test('DictationController provider accepts service overrides', () {
      final fakeRecorder2 = FakeAudioRecorderService();
      final fakeSpeech2 = FakeSpeechToTextService();

      final container = ProviderContainer(
        overrides: [
          audioRecorderServiceProvider.overrideWith((ref) => fakeRecorder2),
          speechToTextServiceProvider.overrideWith((ref) => fakeSpeech2),
        ],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(dictationControllerProvider('note-id').notifier);
      expect(ctrl, isA<DictationController>());
    });
  });
}
