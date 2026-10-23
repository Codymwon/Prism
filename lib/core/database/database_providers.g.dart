// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'26b319498ac504125f88f4831f0d46c86eda15c5';

/// See also [database].
@ProviderFor(database)
final databaseProvider = AutoDisposeFutureProvider<Database>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseRef = AutoDisposeFutureProviderRef<Database>;
String _$notesVersionHash() => r'77664d7764fa61eb568fe02ae14242fdba19dbfa';

/// See also [NotesVersion].
@ProviderFor(NotesVersion)
final notesVersionProvider =
    AutoDisposeNotifierProvider<NotesVersion, int>.internal(
      NotesVersion.new,
      name: r'notesVersionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notesVersionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotesVersion = AutoDisposeNotifier<int>;
String _$foldersVersionHash() => r'207295e131a56727262e3f2e42f9bbaf1e545314';

/// See also [FoldersVersion].
@ProviderFor(FoldersVersion)
final foldersVersionProvider =
    AutoDisposeNotifierProvider<FoldersVersion, int>.internal(
      FoldersVersion.new,
      name: r'foldersVersionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$foldersVersionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FoldersVersion = AutoDisposeNotifier<int>;
String _$tableVersionHash() => r'7700ac2d3ae545e2da3095b49802a5138ff45521';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$TableVersion extends BuildlessAutoDisposeNotifier<int> {
  late final DbTable table;

  int build(DbTable table);
}

/// See also [TableVersion].
@ProviderFor(TableVersion)
const tableVersionProvider = TableVersionFamily();

/// See also [TableVersion].
class TableVersionFamily extends Family<int> {
  /// See also [TableVersion].
  const TableVersionFamily();

  /// See also [TableVersion].
  TableVersionProvider call(DbTable table) {
    return TableVersionProvider(table);
  }

  @override
  TableVersionProvider getProviderOverride(
    covariant TableVersionProvider provider,
  ) {
    return call(provider.table);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tableVersionProvider';
}

/// See also [TableVersion].
class TableVersionProvider
    extends AutoDisposeNotifierProviderImpl<TableVersion, int> {
  /// See also [TableVersion].
  TableVersionProvider(DbTable table)
    : this._internal(
        () => TableVersion()..table = table,
        from: tableVersionProvider,
        name: r'tableVersionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$tableVersionHash,
        dependencies: TableVersionFamily._dependencies,
        allTransitiveDependencies:
            TableVersionFamily._allTransitiveDependencies,
        table: table,
      );

  TableVersionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.table,
  }) : super.internal();

  final DbTable table;

  @override
  int runNotifierBuild(covariant TableVersion notifier) {
    return notifier.build(table);
  }

  @override
  Override overrideWith(TableVersion Function() create) {
    return ProviderOverride(
      origin: this,
      override: TableVersionProvider._internal(
        () => create()..table = table,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        table: table,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<TableVersion, int> createElement() {
    return _TableVersionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TableVersionProvider && other.table == table;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, table.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TableVersionRef on AutoDisposeNotifierProviderRef<int> {
  /// The parameter `table` of this provider.
  DbTable get table;
}

class _TableVersionProviderElement
    extends AutoDisposeNotifierProviderElement<TableVersion, int>
    with TableVersionRef {
  _TableVersionProviderElement(super.provider);

  @override
  DbTable get table => (origin as TableVersionProvider).table;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
