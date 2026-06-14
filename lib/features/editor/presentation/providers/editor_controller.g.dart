// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$editorControllerHash() => r'8135b29bdb0cef9de50f8e43c169acab2fcaa151';

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

abstract class _$EditorController
    extends BuildlessAutoDisposeNotifier<EditorState> {
  late final String noteId;

  EditorState build(String noteId);
}

/// Controller managing the editor state, autosaves, and wikilink autocompletion.
///
/// Copied from [EditorController].
@ProviderFor(EditorController)
const editorControllerProvider = EditorControllerFamily();

/// Controller managing the editor state, autosaves, and wikilink autocompletion.
///
/// Copied from [EditorController].
class EditorControllerFamily extends Family<EditorState> {
  /// Controller managing the editor state, autosaves, and wikilink autocompletion.
  ///
  /// Copied from [EditorController].
  const EditorControllerFamily();

  /// Controller managing the editor state, autosaves, and wikilink autocompletion.
  ///
  /// Copied from [EditorController].
  EditorControllerProvider call(String noteId) {
    return EditorControllerProvider(noteId);
  }

  @override
  EditorControllerProvider getProviderOverride(
    covariant EditorControllerProvider provider,
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
  String? get name => r'editorControllerProvider';
}

/// Controller managing the editor state, autosaves, and wikilink autocompletion.
///
/// Copied from [EditorController].
class EditorControllerProvider
    extends AutoDisposeNotifierProviderImpl<EditorController, EditorState> {
  /// Controller managing the editor state, autosaves, and wikilink autocompletion.
  ///
  /// Copied from [EditorController].
  EditorControllerProvider(String noteId)
    : this._internal(
        () => EditorController()..noteId = noteId,
        from: editorControllerProvider,
        name: r'editorControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$editorControllerHash,
        dependencies: EditorControllerFamily._dependencies,
        allTransitiveDependencies:
            EditorControllerFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  EditorControllerProvider._internal(
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
  EditorState runNotifierBuild(covariant EditorController notifier) {
    return notifier.build(noteId);
  }

  @override
  Override overrideWith(EditorController Function() create) {
    return ProviderOverride(
      origin: this,
      override: EditorControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<EditorController, EditorState>
  createElement() {
    return _EditorControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EditorControllerProvider && other.noteId == noteId;
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
mixin EditorControllerRef on AutoDisposeNotifierProviderRef<EditorState> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _EditorControllerProviderElement
    extends AutoDisposeNotifierProviderElement<EditorController, EditorState>
    with EditorControllerRef {
  _EditorControllerProviderElement(super.provider);

  @override
  String get noteId => (origin as EditorControllerProvider).noteId;
}

String _$dictationControllerHash() =>
    r'b9c818be34c7fd964b11887ab52610de2ad8b207';

abstract class _$DictationController
    extends BuildlessAutoDisposeNotifier<DictationState> {
  late final String noteId;

  DictationState build(String noteId);
}

/// Controller managing live text speech transcribing or audio-memo recording.
///
/// Copied from [DictationController].
@ProviderFor(DictationController)
const dictationControllerProvider = DictationControllerFamily();

/// Controller managing live text speech transcribing or audio-memo recording.
///
/// Copied from [DictationController].
class DictationControllerFamily extends Family<DictationState> {
  /// Controller managing live text speech transcribing or audio-memo recording.
  ///
  /// Copied from [DictationController].
  const DictationControllerFamily();

  /// Controller managing live text speech transcribing or audio-memo recording.
  ///
  /// Copied from [DictationController].
  DictationControllerProvider call(String noteId) {
    return DictationControllerProvider(noteId);
  }

  @override
  DictationControllerProvider getProviderOverride(
    covariant DictationControllerProvider provider,
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
  String? get name => r'dictationControllerProvider';
}

/// Controller managing live text speech transcribing or audio-memo recording.
///
/// Copied from [DictationController].
class DictationControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<DictationController, DictationState> {
  /// Controller managing live text speech transcribing or audio-memo recording.
  ///
  /// Copied from [DictationController].
  DictationControllerProvider(String noteId)
    : this._internal(
        () => DictationController()..noteId = noteId,
        from: dictationControllerProvider,
        name: r'dictationControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dictationControllerHash,
        dependencies: DictationControllerFamily._dependencies,
        allTransitiveDependencies:
            DictationControllerFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  DictationControllerProvider._internal(
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
  DictationState runNotifierBuild(covariant DictationController notifier) {
    return notifier.build(noteId);
  }

  @override
  Override overrideWith(DictationController Function() create) {
    return ProviderOverride(
      origin: this,
      override: DictationControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<DictationController, DictationState>
  createElement() {
    return _DictationControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DictationControllerProvider && other.noteId == noteId;
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
mixin DictationControllerRef on AutoDisposeNotifierProviderRef<DictationState> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _DictationControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<DictationController, DictationState>
    with DictationControllerRef {
  _DictationControllerProviderElement(super.provider);

  @override
  String get noteId => (origin as DictationControllerProvider).noteId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
