import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/editor/domain/audio_recorder_service.dart';
import 'package:prism/features/editor/data/audio_recorder_service_impl.dart';
import 'package:fake_async/fake_async.dart';

class FakeAudioRecorderService implements AudioRecorderService {
  bool hasMicPermission = true;
  bool startCalled = false;
  bool stopCalled = false;
  String? startPath;
  bool recordingActive = false;

  @override
  Future<bool> hasPermission() async => hasMicPermission;

  @override
  Future<void> start(String path) async {
    startCalled = true;
    startPath = path;
    recordingActive = true;
  }

  @override
  Future<String?> stop() async {
    stopCalled = true;
    recordingActive = false;
    return startPath;
  }

  @override
  Future<bool> isRecording() async => recordingActive;

  @override
  void dispose() {}
}

void main() {
  late FakeAudioRecorderService fakeAudioRecorder;
  late ProviderContainer container;
  late TextEditingController textController;
  late FocusNode focusNode;
  bool saveCalled = false;

  setUp(() {
    fakeAudioRecorder = FakeAudioRecorderService();
    textController = TextEditingController(text: 'Initial text');
    focusNode = FocusNode();
    saveCalled = false;

    container = ProviderContainer(
      overrides: [
        audioRecorderServiceProvider.overrideWithValue(fakeAudioRecorder),
        noteByIdProvider('test-note').overrideWith((ref) => Future.value(null)),
      ],
    );
    // Listen to the provider to keep it alive during the test
    container.listen(audioRecordControllerProvider('test-note'), (_, _) {});
  });

  tearDown(() {
    container.dispose();
    textController.dispose();
    focusNode.dispose();
  });

  group('AudioRecordController - Slice 1: Start Recording', () {
    test('toggleRecording when idle starts recording and sets isRecording to true', () async {
      final controller = container.read(audioRecordControllerProvider('test-note').notifier);

      expect(container.read(audioRecordControllerProvider('test-note')).isRecording, isFalse);
      expect(fakeAudioRecorder.startCalled, isFalse);

      await controller.toggleRecording(
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
        vaultPath: 'test_vault',
      );

      expect(container.read(audioRecordControllerProvider('test-note')).isRecording, isTrue);
      expect(fakeAudioRecorder.startCalled, isTrue);
      expect(fakeAudioRecorder.startPath, contains('attachments'));
    });
  });

  group('AudioRecordController - Slice 2: Timer Tick', () {
    test('timer increments durationSeconds every second', () {
      fakeAsync((async) {
        final controller = container.read(audioRecordControllerProvider('test-note').notifier);

        controller.toggleRecording(
          textController: textController,
          focusNode: focusNode,
          onSave: () => saveCalled = true,
          vaultPath: 'test_vault',
        );
        async.flushMicrotasks();

        // At start, duration is 0
        expect(container.read(audioRecordControllerProvider('test-note')).durationSeconds, 0);

        // Elapse 1 second
        async.elapse(const Duration(seconds: 1));
        expect(container.read(audioRecordControllerProvider('test-note')).durationSeconds, 1);

        // Elapse 2 more seconds
        async.elapse(const Duration(seconds: 2));
        expect(container.read(audioRecordControllerProvider('test-note')).durationSeconds, 3);
      });
    });
  });

  group('AudioRecordController - Slice 3: Commit Recording', () {
    test('stopRecording with commit: true stops recording, inserts markdown link, and triggers onSave', () async {
      final controller = container.read(audioRecordControllerProvider('test-note').notifier);

      // Start recording
      await controller.toggleRecording(
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
        vaultPath: 'test_vault',
      );

      expect(container.read(audioRecordControllerProvider('test-note')).isRecording, isTrue);

      // Set cursor in the middle of text
      textController.value = const TextEditingValue(
        text: 'Hello World',
        selection: TextSelection.collapsed(offset: 5),
      );

      await controller.stopRecording(
        commit: true,
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
      );

      final state = container.read(audioRecordControllerProvider('test-note'));
      expect(state.isRecording, isFalse);
      expect(state.durationSeconds, 0);
      expect(fakeAudioRecorder.recordingActive, isFalse);
      expect(fakeAudioRecorder.stopCalled, isTrue);

      // Verify markdown link insertion
      expect(textController.text, contains('[Audio Note](attachments/audio_'));
      expect(textController.text, startsWith('Hello'));
      expect(textController.text, endsWith(' World'));
      expect(saveCalled, isTrue);
    });

    test('toggleRecording when already recording commits the recording', () async {
      final controller = container.read(audioRecordControllerProvider('test-note').notifier);

      await controller.toggleRecording(
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
        vaultPath: 'test_vault',
      );

      expect(container.read(audioRecordControllerProvider('test-note')).isRecording, isTrue);

      await controller.toggleRecording(
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
        vaultPath: 'test_vault',
      );

      final state = container.read(audioRecordControllerProvider('test-note'));
      expect(state.isRecording, isFalse);
      expect(saveCalled, isTrue);
    });
  });

  group('AudioRecordController - Slice 4: Cancel Recording', () {
    test('stopRecording with commit: false discards recording and deletes file', () async {
      final controller = container.read(audioRecordControllerProvider('test-note').notifier);

      await controller.toggleRecording(
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
        vaultPath: 'test_vault',
      );

      expect(container.read(audioRecordControllerProvider('test-note')).isRecording, isTrue);

      // Create a dummy file at the expected path so we can check if it gets deleted
      final audioPath = fakeAudioRecorder.startPath!;
      final file = File(audioPath);
      await file.create(recursive: true);
      expect(file.existsSync(), isTrue);

      await controller.stopRecording(
        commit: false,
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
      );

      final state = container.read(audioRecordControllerProvider('test-note'));
      expect(state.isRecording, isFalse);
      expect(fakeAudioRecorder.recordingActive, isFalse);
      expect(textController.text, equals('Initial text')); // No link inserted
      expect(saveCalled, isFalse);

      // Verify file is deleted
      expect(file.existsSync(), isFalse);
    });
  });

  group('AudioRecordController - Slice 5: Dispose Clean-up', () {
    test('disposing controller while recording stops recorder and deletes file', () async {
      final localContainer = ProviderContainer(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(fakeAudioRecorder),
          noteByIdProvider('test-note').overrideWith((ref) => Future.value(null)),
        ],
      );
      localContainer.listen(audioRecordControllerProvider('test-note'), (_, _) {});

      final controller = localContainer.read(audioRecordControllerProvider('test-note').notifier);

      await controller.toggleRecording(
        textController: textController,
        focusNode: focusNode,
        onSave: () => saveCalled = true,
        vaultPath: 'test_vault',
      );

      expect(localContainer.read(audioRecordControllerProvider('test-note')).isRecording, isTrue);

      final audioPath = fakeAudioRecorder.startPath!;
      final file = File(audioPath);
      await file.create(recursive: true);
      expect(file.existsSync(), isTrue);

      localContainer.dispose();

      expect(fakeAudioRecorder.recordingActive, isFalse);
      expect(file.existsSync(), isFalse);
    });
  });
}
