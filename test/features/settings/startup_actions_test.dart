import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/settings/presentation/providers/settings_provider.dart';
import 'package:prism/features/settings/presentation/providers/startup_actions.dart';
import 'package:prism/core/utils/utils.dart';

class MockRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository() : super(MockRef());

  final Map<String, Note> _notes = {};

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final note = Note(
      id: 'test_note_id',
      title: title ?? 'Untitled',
      filePath: '',
      wordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDaily: isDaily,
      dailyDate: dailyDate,
    );
    if (dailyDate != null) {
      _notes[dailyDate] = note;
    }
    return note;
  }

  @override
  Future<Note?> getDailyNote(String date) async {
    return _notes[date];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeNoteRepository fakeRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeRepo = FakeNoteRepository();
    container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Startup Actions Tests', () {
    test('does nothing if auto-create daily note is disabled', () async {
      // Setup: ensure autoCreateDailyNoteOnLaunch is false
      await container.read(autoCreateDailyNoteOnLaunchProvider.notifier).setEnabled(false);

      final route = await checkAndRunStartupActions(container.read);
      expect(route, isNull);
    });

    test('creates daily note and returns route if enabled and note does not exist', () async {
      // Setup: ensure autoCreateDailyNoteOnLaunch is true
      await container.read(autoCreateDailyNoteOnLaunchProvider.notifier).setEnabled(true);

      final todayStr = formatDailyDate(DateTime.now());
      final existing = await fakeRepo.getDailyNote(todayStr);
      expect(existing, isNull);

      final route = await checkAndRunStartupActions(container.read);
      expect(route, isNotNull);
      expect(route, contains('/editor/test_note_id'));
      expect(route, contains('date=$todayStr'));
      expect(route, contains('new=true'));

      // Check note was created
      final after = await fakeRepo.getDailyNote(todayStr);
      expect(after, isNotNull);
      expect(after!.isDaily, isTrue);
    });

    test('does not create daily note if already exists', () async {
      // Setup: ensure autoCreateDailyNoteOnLaunch is true
      await container.read(autoCreateDailyNoteOnLaunchProvider.notifier).setEnabled(true);

      final todayStr = formatDailyDate(DateTime.now());
      // Create it beforehand
      await fakeRepo.createNote(
        title: todayStr,
        isDaily: true,
        dailyDate: todayStr,
      );

      final route = await checkAndRunStartupActions(container.read);
      expect(route, isNull);
    });

    test('runs only once per session due to evaluated flag', () async {
      // Setup: ensure autoCreateDailyNoteOnLaunch is true
      await container.read(autoCreateDailyNoteOnLaunchProvider.notifier).setEnabled(true);

      // Run 1st time (creates note)
      final route1 = await checkAndRunStartupActions(container.read);
      expect(route1, isNotNull);

      // Delete note so it would create it again if it checked
      fakeRepo._notes.clear();

      // Run 2nd time (should return null because evaluated is true)
      expect(container.read(startupActionsEvaluatedProvider), isTrue);

      final route2 = await checkAndRunStartupActions(container.read);
      expect(route2, isNull);
    });
  });
}
