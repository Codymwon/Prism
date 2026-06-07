import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:meridian/features/journal/presentation/providers/journal_providers.dart';
import 'package:meridian/core/database/database_providers.dart';
import 'package:meridian/core/utils/utils.dart';

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
}
