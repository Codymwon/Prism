import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_providers.dart';
import 'prism_metadata_store.dart';

// ─── Abstract Interface ────────────────────────────────────────────────────────

/// A domain-level seam over the raw sqflite [Database].
///
/// All feature repositories should depend on [DatabaseService] rather than
/// importing [Database] directly. This makes every repository unit-testable
/// without hitting the file system.
abstract class DatabaseService {
  /// Executes a raw SQL statement (DDL or DML) with optional [arguments].
  Future<void> execute(String sql, [List<Object?>? arguments]);

  /// Runs a structured query on [table] with optional filtering/ordering.
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });

  /// Executes a raw SQL SELECT query with optional [arguments].
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);

  /// Inserts [values] into [table], returning the row id.
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm? conflictAlgorithm,
  });

  /// Updates rows in [table] matching [where] with [values].
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// Deletes rows from [table] matching [where].
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// Runs [action] inside a database transaction.
  ///
  /// If [action] throws, the transaction is automatically rolled back.
  /// The [DatabaseService] passed to [action] is scoped to the transaction
  /// so callers do not need to hold a reference to the raw [Transaction].
  Future<T> transaction<T>(Future<T> Function(DatabaseService txn) action);

  /// Atomically serialises the five app-only metadata tables to the sidecar
  /// JSON file at [vaultPath].  No-op if [vaultPath] is empty.
  Future<void> flushMetadata(String vaultPath);
}

// ─── SQLite Adapter ───────────────────────────────────────────────────────────

/// Production adapter that wraps a sqflite [Database] (or [Transaction]).
class SqliteDatabaseService implements DatabaseService {
  final DatabaseExecutor _db;

  const SqliteDatabaseService(this._db);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) {
    return _db.execute(sql, arguments);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) {
    return _db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _db.rawQuery(sql, arguments);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return _db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseService txn) action) {
    // If _db is already a Transaction, sqflite does not support nested
    // transactions — we re-use the same executor for the inner call.
    if (_db is Transaction) {
      return action(this);
    }
    return (_db as Database).transaction<T>((txn) {
      return action(SqliteDatabaseService(txn));
    });
  }

  @override
  Future<void> flushMetadata(String vaultPath) async {
    if (vaultPath.isEmpty) return;
    // flushFromDatabase requires the root Database, not a Transaction.
    // When _db is a Transaction this is a no-op (the caller's commit will flush).
    final db = _db;
    if (db is Database) {
      await PrismMetadataStore().flushFromDatabase(db, vaultPath);
    }
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides a [DatabaseService] that is tied to the currently active vault's
/// [Database].  Automatically invalidated when the vault changes.
final databaseServiceProvider = FutureProvider<DatabaseService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SqliteDatabaseService(db);
});
