// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'1ec854ddf1e1afb2f4dbab921747e3f1f359b69b';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
