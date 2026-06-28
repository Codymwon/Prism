// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeVaultPathHash() => r'9f532fe7d6ee6db519f203d9fc31a6799b0db21e';

/// See also [activeVaultPath].
@ProviderFor(activeVaultPath)
final activeVaultPathProvider = AutoDisposeFutureProvider<String>.internal(
  activeVaultPath,
  name: r'activeVaultPathProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeVaultPathHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveVaultPathRef = AutoDisposeFutureProviderRef<String>;
String _$baseVaultsDirectoryHash() =>
    r'f9c1a45ef7d733d186a217df474d7c678dc781e0';

/// See also [BaseVaultsDirectory].
@ProviderFor(BaseVaultsDirectory)
final baseVaultsDirectoryProvider =
    AutoDisposeAsyncNotifierProvider<BaseVaultsDirectory, String>.internal(
      BaseVaultsDirectory.new,
      name: r'baseVaultsDirectoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$baseVaultsDirectoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BaseVaultsDirectory = AutoDisposeAsyncNotifier<String>;
String _$activeVaultNameHash() => r'0ad45e0f21e105be428730ae1a41ae69bb9ba38b';

/// See also [ActiveVaultName].
@ProviderFor(ActiveVaultName)
final activeVaultNameProvider =
    AutoDisposeAsyncNotifierProvider<ActiveVaultName, String>.internal(
      ActiveVaultName.new,
      name: r'activeVaultNameProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeVaultNameHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveVaultName = AutoDisposeAsyncNotifier<String>;
String _$syncedVaultsHash() => r'ba8a7a912037f50ea47622e2274ac8d9efd80612';

/// See also [SyncedVaults].
@ProviderFor(SyncedVaults)
final syncedVaultsProvider =
    AutoDisposeAsyncNotifierProvider<SyncedVaults, List<String>>.internal(
      SyncedVaults.new,
      name: r'syncedVaultsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncedVaultsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncedVaults = AutoDisposeAsyncNotifier<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
