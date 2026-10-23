// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_bookmark_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioBookmarkRepositoryHash() =>
    r'468125f7bee838a4fe32920e376da50144ee6e4c';

/// Provider for the [AudioBookmarkRepository] singleton.
///
/// Copied from [audioBookmarkRepository].
@ProviderFor(audioBookmarkRepository)
final audioBookmarkRepositoryProvider =
    AutoDisposeProvider<AudioBookmarkRepository>.internal(
      audioBookmarkRepository,
      name: r'audioBookmarkRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioBookmarkRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioBookmarkRepositoryRef =
    AutoDisposeProviderRef<AudioBookmarkRepository>;
String _$audioBookmarkNotifierHash() =>
    r'c970f7ef6da0d2868042b398100042815800d205';

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

abstract class _$AudioBookmarkNotifier
    extends BuildlessAutoDisposeNotifier<AudioBookmarkState> {
  late final BookmarkKey key;

  AudioBookmarkState build(BookmarkKey key);
}

/// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
///
/// Copied from [AudioBookmarkNotifier].
@ProviderFor(AudioBookmarkNotifier)
const audioBookmarkNotifierProvider = AudioBookmarkNotifierFamily();

/// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
///
/// Copied from [AudioBookmarkNotifier].
class AudioBookmarkNotifierFamily extends Family<AudioBookmarkState> {
  /// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
  ///
  /// Copied from [AudioBookmarkNotifier].
  const AudioBookmarkNotifierFamily();

  /// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
  ///
  /// Copied from [AudioBookmarkNotifier].
  AudioBookmarkNotifierProvider call(BookmarkKey key) {
    return AudioBookmarkNotifierProvider(key);
  }

  @override
  AudioBookmarkNotifierProvider getProviderOverride(
    covariant AudioBookmarkNotifierProvider provider,
  ) {
    return call(provider.key);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'audioBookmarkNotifierProvider';
}

/// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
///
/// Copied from [AudioBookmarkNotifier].
class AudioBookmarkNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AudioBookmarkNotifier,
          AudioBookmarkState
        > {
  /// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
  ///
  /// Copied from [AudioBookmarkNotifier].
  AudioBookmarkNotifierProvider(BookmarkKey key)
    : this._internal(
        () => AudioBookmarkNotifier()..key = key,
        from: audioBookmarkNotifierProvider,
        name: r'audioBookmarkNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$audioBookmarkNotifierHash,
        dependencies: AudioBookmarkNotifierFamily._dependencies,
        allTransitiveDependencies:
            AudioBookmarkNotifierFamily._allTransitiveDependencies,
        key: key,
      );

  AudioBookmarkNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
  }) : super.internal();

  final BookmarkKey key;

  @override
  AudioBookmarkState runNotifierBuild(
    covariant AudioBookmarkNotifier notifier,
  ) {
    return notifier.build(key);
  }

  @override
  Override overrideWith(AudioBookmarkNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AudioBookmarkNotifierProvider._internal(
        () => create()..key = key,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AudioBookmarkNotifier, AudioBookmarkState>
  createElement() {
    return _AudioBookmarkNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AudioBookmarkNotifierProvider && other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AudioBookmarkNotifierRef
    on AutoDisposeNotifierProviderRef<AudioBookmarkState> {
  /// The parameter `key` of this provider.
  BookmarkKey get key;
}

class _AudioBookmarkNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AudioBookmarkNotifier,
          AudioBookmarkState
        >
    with AudioBookmarkNotifierRef {
  _AudioBookmarkNotifierProviderElement(super.provider);

  @override
  BookmarkKey get key => (origin as AudioBookmarkNotifierProvider).key;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
