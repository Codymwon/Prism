// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_record_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioRecordControllerHash() =>
    r'79bf51d3a93d9903657e5eae2775611687142bec';

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

abstract class _$AudioRecordController
    extends BuildlessAutoDisposeNotifier<AudioRecordState> {
  late final String noteId;

  AudioRecordState build(String noteId);
}

/// Controller managing audio note recording and timer.
///
/// Copied from [AudioRecordController].
@ProviderFor(AudioRecordController)
const audioRecordControllerProvider = AudioRecordControllerFamily();

/// Controller managing audio note recording and timer.
///
/// Copied from [AudioRecordController].
class AudioRecordControllerFamily extends Family<AudioRecordState> {
  /// Controller managing audio note recording and timer.
  ///
  /// Copied from [AudioRecordController].
  const AudioRecordControllerFamily();

  /// Controller managing audio note recording and timer.
  ///
  /// Copied from [AudioRecordController].
  AudioRecordControllerProvider call(String noteId) {
    return AudioRecordControllerProvider(noteId);
  }

  @override
  AudioRecordControllerProvider getProviderOverride(
    covariant AudioRecordControllerProvider provider,
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
  String? get name => r'audioRecordControllerProvider';
}

/// Controller managing audio note recording and timer.
///
/// Copied from [AudioRecordController].
class AudioRecordControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AudioRecordController,
          AudioRecordState
        > {
  /// Controller managing audio note recording and timer.
  ///
  /// Copied from [AudioRecordController].
  AudioRecordControllerProvider(String noteId)
    : this._internal(
        () => AudioRecordController()..noteId = noteId,
        from: audioRecordControllerProvider,
        name: r'audioRecordControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$audioRecordControllerHash,
        dependencies: AudioRecordControllerFamily._dependencies,
        allTransitiveDependencies:
            AudioRecordControllerFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  AudioRecordControllerProvider._internal(
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
  AudioRecordState runNotifierBuild(covariant AudioRecordController notifier) {
    return notifier.build(noteId);
  }

  @override
  Override overrideWith(AudioRecordController Function() create) {
    return ProviderOverride(
      origin: this,
      override: AudioRecordControllerProvider._internal(
        () => create()..noteId = noteId,
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
  AutoDisposeNotifierProviderElement<AudioRecordController, AudioRecordState>
  createElement() {
    return _AudioRecordControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AudioRecordControllerProvider && other.noteId == noteId;
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
mixin AudioRecordControllerRef
    on AutoDisposeNotifierProviderRef<AudioRecordState> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _AudioRecordControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AudioRecordController,
          AudioRecordState
        >
    with AudioRecordControllerRef {
  _AudioRecordControllerProviderElement(super.provider);

  @override
  String get noteId => (origin as AudioRecordControllerProvider).noteId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
