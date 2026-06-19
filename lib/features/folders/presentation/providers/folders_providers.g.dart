// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folders_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$foldersHash() => r'b720e3bdfa13c7f30fabc23197cf4f318ca60450';

/// See also [folders].
@ProviderFor(folders)
final foldersProvider = AutoDisposeFutureProvider<List<VirtualFolder>>.internal(
  folders,
  name: r'foldersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$foldersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FoldersRef = AutoDisposeFutureProviderRef<List<VirtualFolder>>;
String _$foldersForNoteHash() => r'561cb5dbed32c09f22364af9eff8641bd23b8a80';

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

/// See also [foldersForNote].
@ProviderFor(foldersForNote)
const foldersForNoteProvider = FoldersForNoteFamily();

/// See also [foldersForNote].
class FoldersForNoteFamily extends Family<AsyncValue<List<VirtualFolder>>> {
  /// See also [foldersForNote].
  const FoldersForNoteFamily();

  /// See also [foldersForNote].
  FoldersForNoteProvider call(String noteId) {
    return FoldersForNoteProvider(noteId);
  }

  @override
  FoldersForNoteProvider getProviderOverride(
    covariant FoldersForNoteProvider provider,
  ) {
    return call(provider.noteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'foldersForNoteProvider';
}

/// See also [foldersForNote].
class FoldersForNoteProvider
    extends AutoDisposeFutureProvider<List<VirtualFolder>> {
  /// See also [foldersForNote].
  FoldersForNoteProvider(String noteId)
    : this._internal(
        (ref) => foldersForNote(ref as FoldersForNoteRef, noteId),
        from: foldersForNoteProvider,
        name: r'foldersForNoteProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$foldersForNoteHash,
        dependencies: FoldersForNoteFamily._dependencies,
        allTransitiveDependencies:
            FoldersForNoteFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  FoldersForNoteProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final String noteId;

  @override
  Override overrideWith(
    FutureOr<List<VirtualFolder>> Function(FoldersForNoteRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FoldersForNoteProvider._internal(
        (ref) => create(ref as FoldersForNoteRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VirtualFolder>> createElement() {
    return _FoldersForNoteProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FoldersForNoteProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FoldersForNoteRef on AutoDisposeFutureProviderRef<List<VirtualFolder>> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _FoldersForNoteProviderElement
    extends AutoDisposeFutureProviderElement<List<VirtualFolder>>
    with FoldersForNoteRef {
  _FoldersForNoteProviderElement(super.provider);

  @override
  String get noteId => (origin as FoldersForNoteProvider).noteId;
}

String _$noteFolderMappingsHash() =>
    r'213a3f144f552a2d7dd9f64bfa6ea9fca87338ae';

/// See also [noteFolderMappings].
@ProviderFor(noteFolderMappings)
final noteFolderMappingsProvider =
    AutoDisposeFutureProvider<Map<String, List<String>>>.internal(
      noteFolderMappings,
      name: r'noteFolderMappingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$noteFolderMappingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NoteFolderMappingsRef =
    AutoDisposeFutureProviderRef<Map<String, List<String>>>;
String _$selectedFolderIdHash() => r'126d9050c57373b7f1b9a04c1439a5eba1d7a252';

/// See also [SelectedFolderId].
@ProviderFor(SelectedFolderId)
final selectedFolderIdProvider =
    AutoDisposeNotifierProvider<SelectedFolderId, String?>.internal(
      SelectedFolderId.new,
      name: r'selectedFolderIdProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedFolderIdHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedFolderId = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
