import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_providers.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(ref);
});

class JournalRepository {
  final Ref _ref;

  JournalRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  Future<Set<String>> getAllDailyDates() async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      columns: ['daily_date'],
      where: 'is_daily = 1 AND is_ghost = 0',
    );
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return maps
        .map((m) => m['daily_date'] as String?)
        .where((d) => d != null && d.isNotEmpty && datePattern.hasMatch(d))
        .cast<String>()
        .toSet();
  }
}
