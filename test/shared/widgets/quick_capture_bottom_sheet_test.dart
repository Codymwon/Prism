import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/providers/shared_preferences_provider.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/features/editor/data/audio_recorder_service_impl.dart';
import 'package:prism/features/editor/domain/audio_recorder_service.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/folders/presentation/providers/folders_providers.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/shared/widgets/quick_capture_bottom_sheet.dart';
import 'package:prism/l10n/l10n.dart';

class FakeAudioRecorderService implements AudioRecorderService {
  String? recordedToPath;
  bool isRecordingState = false;
  bool hasPermissionValue = true;

  @override
  Future<bool> hasPermission() async => hasPermissionValue;

  @override
  Future<void> start(String path) async {
    recordedToPath = path;
    isRecordingState = true;
    // Create an empty dummy file so File(path).existsSync() returns true
    final file = File(path);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync('dummy audio content');
  }

  @override
  Future<String?> stop() async {
    isRecordingState = false;
    return recordedToPath;
  }

  @override
  Future<bool> isRecording() async => isRecordingState;

  @override
  void dispose() {
    isRecordingState = false;
  }
}

class FakeNoteRepository extends Fake implements NoteRepository {
  final List<Note> createdNotes = [];

  @override
  Future<Note?> getDailyNote(String dateStr) async => null;

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final note = Note(
      id: 'fake-note-${createdNotes.length + 1}',
      title: title ?? 'Untitled',
      filePath: '${title ?? 'Untitled'}.md',
      wordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDaily: isDaily,
    );
    createdNotes.add(note);
    return note;
  }
}

class FakeTutorialState extends TutorialState {
  @override
  bool build() => true;
  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

class FakeJournalTutorialState extends JournalTutorialState {
  @override
  bool build() => true;
  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

void main() {
  late FakeAudioRecorderService fakeRecorderService;
  late FakeNoteRepository fakeNoteRepo;
  late SharedPreferences prefs;
  late Directory tempDir;

  setUp(() async {
    fakeRecorderService = FakeAudioRecorderService();
    fakeNoteRepo = FakeNoteRepository();
    SharedPreferences.setMockInitialValues({
      'has_accepted_audio_recording_notice': true,
    });
    prefs = await SharedPreferences.getInstance();
    tempDir = Directory.systemTemp.createTempSync('prism_qc_test_');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  List<Override> createOverrides() {
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioRecorderServiceProvider.overrideWithValue(fakeRecorderService),
      noteRepositoryProvider.overrideWithValue(fakeNoteRepo),
      activeVaultPathProvider.overrideWith((ref) async => tempDir.path),
      tutorialStateProvider.overrideWith(FakeTutorialState.new),
      journalTutorialStateProvider.overrideWith(FakeJournalTutorialState.new),
      foldersProvider.overrideWith((ref) async => <VirtualFolder>[]),
    ];
  }

  group('QuickCaptureNotifier Unit Tests', () {
    test('initial state is closed', () {
      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      final state = container.read(quickCaptureNotifierProvider);
      expect(state.isOpen, isFalse);
      expect(state.mode, QuickCaptureMode.actions);
      expect(state.durationSeconds, 0);
      expect(state.audioPath, isNull);
    });

    test('open() and dismiss() lifecycle', () {
      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      final notifier = container.read(quickCaptureNotifierProvider.notifier);
      notifier.open();

      var state = container.read(quickCaptureNotifierProvider);
      expect(state.isOpen, isTrue);
      expect(state.mode, QuickCaptureMode.actions);

      notifier.dismiss();
      state = container.read(quickCaptureNotifierProvider);
      expect(state.isOpen, isFalse);
    });

    test('cancelRecording() discards recording and resets state', () async {
      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      final notifier = container.read(quickCaptureNotifierProvider.notifier);
      notifier.open();

      // Simulate recording state
      await container.read(quickCaptureNotifierProvider.notifier).cancelRecording();
      final state = container.read(quickCaptureNotifierProvider);
      expect(state.isOpen, isFalse);
    });
  });

  group('QuickCaptureModalFallback Widget Tests', () {
    testWidgets('renders action deck options when open in fallback sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      QuickCapture.show(context);
                    },
                    child: const Text('Launch QC'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap launch button -> opens fallback modal sheet
      await tester.tap(find.text('Launch QC'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('quick_capture_actions_deck')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_record_voice_memo')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_blank_document')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_close')), findsOneWidget);

      // Tap Blank Document -> calls createNote
      await tester.tap(find.byKey(const ValueKey('quick_capture_blank_document')));
      await tester.pumpAndSettle();

      expect(fakeNoteRepo.createdNotes.length, 1);
    });

    testWidgets('starts recording and commits voice memo note in fallback sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      QuickCapture.show(context);
                    },
                    child: const Text('Launch QC'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch QC'));
      await tester.pumpAndSettle();

      // Tap Record Voice Memo
      await tester.tap(find.byKey(const ValueKey('quick_capture_record_voice_memo')));
      await tester.pump(const Duration(milliseconds: 300));

      // Recording deck should be visible
      expect(find.byKey(const ValueKey('quick_capture_recording_deck')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_cancel')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_commit')),
          findsOneWidget);
      expect(fakeRecorderService.isRecordingState, isTrue);

      // Tap Save Recording
      await tester.tap(find.byKey(const ValueKey('quick_capture_commit')));
      await tester.pump(const Duration(milliseconds: 300));

      // Recorder stopped and voice memo note created in inbox
      expect(fakeRecorderService.isRecordingState, isFalse);
      expect(fakeNoteRepo.createdNotes.length, 1);
      final createdNote = fakeNoteRepo.createdNotes.first;
      expect(createdNote.title, startsWith('Voice Memo —'));
    });
  });

  group('AppShell Quick Capture Bloom Tests', () {
    testWidgets('FAB on Notes tab opens Quick Capture Deck and Scrim dismisses it',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(
              currentPath: '/notes',
              child: Scaffold(body: Text('Notes Screen Body')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Notes tab should be active
      expect(find.text('Notes Screen Body'), findsOneWidget);

      // Initially Quick Capture is closed
      expect(find.byKey(const ValueKey('quick_capture_actions_deck')),
          findsNothing);

      // Tap the FAB (+) button
      await tester.tap(find.byKey(const ValueKey('app_shell_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Quick Capture Deck should bloom into view
      expect(find.byKey(const ValueKey('quick_capture_actions_deck')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_record_voice_memo')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_blank_document')),
          findsOneWidget);

      // Scrim should be present
      expect(find.byKey(const ValueKey('island_modal_scrim')), findsOneWidget);

      // Tap scrim to dismiss
      await tester.tap(find.byKey(const ValueKey('island_modal_scrim')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Quick Capture Deck dismissed
      expect(find.byKey(const ValueKey('quick_capture_actions_deck')),
          findsNothing);
    });
  });
}
