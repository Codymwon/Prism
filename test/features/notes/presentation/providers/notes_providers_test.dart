import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/features/journal/presentation/providers/journal_providers.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/utils/utils.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notes (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              file_path TEXT NOT NULL UNIQUE,
              word_count INTEGER DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              is_ghost INTEGER DEFAULT 0,
              is_daily INTEGER DEFAULT 0,
              daily_date TEXT,
              is_conflicted INTEGER DEFAULT 0,
              original_note_id TEXT,
              snippet TEXT DEFAULT ''
            )
          ''');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('journalStreakProvider calculates correct streak and total daily note count', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
      ],
    );
    addTearDown(container.dispose);

    // 1. Initial State: No daily notes
    var streakData = await container.read(journalStreakProvider.future);
    expect(streakData.streak, equals(0));
    expect(streakData.totalCount, equals(0));

    // Helper to insert a daily note
    Future<void> insertDailyNote(String dateStr) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('notes', {
        'id': 'note-$dateStr',
        'title': dateStr,
        'file_path': '/vault/$dateStr.md',
        'word_count': 100,
        'created_at': now,
        'updated_at': now,
        'is_ghost': 0,
        'is_daily': 1,
        'daily_date': dateStr,
      });
      // Force riverpod provider refresh
      container.read(notesVersionProvider.notifier).state++;
    }

    final today = formatDailyDate(DateTime.now());
    final yesterday = formatDailyDate(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = formatDailyDate(DateTime.now().subtract(const Duration(days: 2)));
    final fiveDaysAgo = formatDailyDate(DateTime.now().subtract(const Duration(days: 5)));

    // 2. Add today's daily note
    await insertDailyNote(today);
    streakData = await container.read(journalStreakProvider.future);
    expect(streakData.streak, equals(1));
    expect(streakData.totalCount, equals(1));

    // 3. Add yesterday's daily note -> Streak becomes 2
    await insertDailyNote(yesterday);
    streakData = await container.read(journalStreakProvider.future);
    expect(streakData.streak, equals(2));
    expect(streakData.totalCount, equals(2));

    // 4. Add 2 days ago note -> Streak becomes 3
    await insertDailyNote(twoDaysAgo);
    streakData = await container.read(journalStreakProvider.future);
    expect(streakData.streak, equals(3));
    expect(streakData.totalCount, equals(3));

    // 5. Add 5 days ago note -> Streak stays 3, totalCount becomes 4 (since 3 days ago is missing)
    await insertDailyNote(fiveDaysAgo);
    streakData = await container.read(journalStreakProvider.future);
    expect(streakData.streak, equals(3));
    expect(streakData.totalCount, equals(4));
  });

  test('journalStreakProvider allows today to be pending if yesterday was written', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
      ],
    );
    addTearDown(container.dispose);

    // Helper to insert a daily note
    Future<void> insertDailyNote(String dateStr) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('notes', {
        'id': 'note-$dateStr',
        'title': dateStr,
        'file_path': '/vault/$dateStr.md',
        'word_count': 100,
        'created_at': now,
        'updated_at': now,
        'is_ghost': 0,
        'is_daily': 1,
        'daily_date': dateStr,
      });
      container.read(notesVersionProvider.notifier).state++;
    }

    final yesterday = formatDailyDate(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = formatDailyDate(DateTime.now().subtract(const Duration(days: 2)));

    // Write yesterday and 2 days ago (today is not written yet)
    await insertDailyNote(yesterday);
    await insertDailyNote(twoDaysAgo);

    final streakData = await container.read(journalStreakProvider.future);
    // Streak should be 2, because today's entry is allowed to be pending
    expect(streakData.streak, equals(2));
    expect(streakData.totalCount, equals(2));
  });

  test('journalStreakProvider handles null, empty, or malformed dates gracefully', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
      ],
    );
    addTearDown(container.dispose);

    // Insert daily notes with bad dates
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('notes', {
      'id': 'note-null',
      'title': 'Null Date',
      'file_path': '/vault/null.md',
      'word_count': 10,
      'created_at': now,
      'updated_at': now,
      'is_ghost': 0,
      'is_daily': 1,
      'daily_date': null,
    });
    await db.insert('notes', {
      'id': 'note-empty',
      'title': 'Empty Date',
      'file_path': '/vault/empty.md',
      'word_count': 10,
      'created_at': now,
      'updated_at': now,
      'is_ghost': 0,
      'is_daily': 1,
      'daily_date': '',
    });
    await db.insert('notes', {
      'id': 'note-malformed',
      'title': 'Malformed Date',
      'file_path': '/vault/malformed.md',
      'word_count': 10,
      'created_at': now,
      'updated_at': now,
      'is_ghost': 0,
      'is_daily': 1,
      'daily_date': 'not-a-date',
    });

    final streakData = await container.read(journalStreakProvider.future);
    // Should gracefully skip these invalid entries and count streak as 0, totalCount as 0
    expect(streakData.streak, equals(0));
    expect(streakData.totalCount, equals(0));
  });

  test('noteDetailsProvider caches data per noteId and invalidates correctly when version changes', () async {
    // Create note_tags table needed for noteDetailsProvider
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_tags (
        note_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (note_id, tag)
      )
    ''');

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
      ],
    );
    addTearDown(container.dispose);

    // Insert initial note and tags
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('notes', {
      'id': 'note-abc',
      'title': 'Test Note ABC',
      'file_path': '/vault/abc.md',
      'word_count': 50,
      'created_at': now,
      'updated_at': now,
      'snippet': 'Initial snippet content',
    });
    await db.insert('note_tags', {
      'note_id': 'note-abc',
      'tag': 'first',
    });

    // Listen to the provider to keep it alive in cache
    final sub = container.listen(noteDetailsProvider('note-abc'), (prev, next) {});

    // Read provider first time
    var details = await container.read(noteDetailsProvider('note-abc').future);
    expect(details.snippet, equals('Initial snippet content'));
    expect(details.tags, equals(['first']));

    // Modify note in DB directly (simulation of update)
    await db.update(
      'notes',
      {'snippet': 'Updated snippet content'},
      where: 'id = ?',
      whereArgs: ['note-abc'],
    );
    await db.insert('note_tags', {
      'note_id': 'note-abc',
      'tag': 'second',
    });

    // Reading again before bumping version should still return cached info (due to provider cache)
    var detailsCached = await container.read(noteDetailsProvider('note-abc').future);
    expect(detailsCached.snippet, equals('Initial snippet content'));

    // Bump version to invalidate cache
    container.read(notesVersionProvider.notifier).state++;

    // Read provider again - should have updated snippet and tags
    var detailsUpdated = await container.read(noteDetailsProvider('note-abc').future);
    expect(detailsUpdated.snippet, equals('Updated snippet content'));
    expect(detailsUpdated.tags, containsAll(['first', 'second']));

    sub.close();
  });

  test('recentNotesProvider returns 5 most recently updated notes (standard & daily) and excludes ghost notes', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
      ],
    );
    addTearDown(container.dispose);

    // Insert 6 notes with different update timestamps, plus 1 ghost note
    // Note 1 (newest)
    await db.insert('notes', {
      'id': 'note-1',
      'title': 'Note 1',
      'file_path': '/vault/1.md',
      'word_count': 10,
      'created_at': 100,
      'updated_at': 600, // Newest
      'is_ghost': 0,
      'is_daily': 0,
    });
    // Note 2 (daily note)
    await db.insert('notes', {
      'id': 'note-2',
      'title': '2026-06-25',
      'file_path': '/vault/2026-06-25.md',
      'word_count': 10,
      'created_at': 100,
      'updated_at': 500,
      'is_ghost': 0,
      'is_daily': 1,
      'daily_date': '2026-06-25',
    });
    // Note 3 (standard note)
    await db.insert('notes', {
      'id': 'note-3',
      'title': 'Note 3',
      'file_path': '/vault/3.md',
      'word_count': 10,
      'created_at': 100,
      'updated_at': 400,
      'is_ghost': 0,
      'is_daily': 0,
    });
    // Note 4
    await db.insert('notes', {
      'id': 'note-4',
      'title': 'Note 4',
      'file_path': '/vault/4.md',
      'word_count': 10,
      'created_at': 100,
      'updated_at': 300,
      'is_ghost': 0,
      'is_daily': 0,
    });
    // Note 5
    await db.insert('notes', {
      'id': 'note-5',
      'title': 'Note 5',
      'file_path': '/vault/5.md',
      'word_count': 10,
      'created_at': 100,
      'updated_at': 200,
      'is_ghost': 0,
      'is_daily': 0,
    });
    // Note 6 (oldest real note)
    await db.insert('notes', {
      'id': 'note-6',
      'title': 'Note 6',
      'file_path': '/vault/6.md',
      'word_count': 10,
      'created_at': 100,
      'updated_at': 100,
      'is_ghost': 0,
      'is_daily': 0,
    });
    // Note 7 (ghost note)
    await db.insert('notes', {
      'id': 'note-7',
      'title': 'Ghost Note',
      'file_path': '/vault/7.md',
      'word_count': 0,
      'created_at': 100,
      'updated_at': 700, // Even newer but ghost!
      'is_ghost': 1,
      'is_daily': 0,
    });

    final recent = await container.read(recentNotesProvider.future);

    // Verify it returned exactly 5 notes
    expect(recent.length, equals(5));

    // Verify correct order (newest first, excluding the ghost note 7)
    expect(recent[0].id, equals('note-1')); // 600
    expect(recent[1].id, equals('note-2')); // 500
    expect(recent[2].id, equals('note-3')); // 400
    expect(recent[3].id, equals('note-4')); // 300
    expect(recent[4].id, equals('note-5')); // 200 (note-6 is excluded because of count limit 5)
  });

  test('NoteSortNotifier loads initial value from SharedPreferences and persists changes', () async {
    SharedPreferences.setMockInitialValues({
      'note_sort_preference': NoteSort.title.index,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Verify it updated to the saved value on build
    final loadedSort = container.read(noteSortNotifierProvider);
    expect(loadedSort, equals(NoteSort.title));

    // Save a new value
    container.read(noteSortNotifierProvider.notifier).state = NoteSort.created;
    // Wait for async _save() to complete
    await Future.delayed(Duration.zero);

    // Verify it saved in SharedPreferences
    expect(prefs.getInt('note_sort_preference'), equals(NoteSort.created.index));
  });
}
