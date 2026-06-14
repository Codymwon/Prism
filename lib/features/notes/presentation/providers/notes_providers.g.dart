// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesHash() => r'a3d4439893597cc9b7c0ba3563ba70428d78db11';

/// See also [notes].
@ProviderFor(notes)
final notesProvider = AutoDisposeFutureProvider<List<Note>>.internal(
  notes,
  name: r'notesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotesRef = AutoDisposeFutureProviderRef<List<Note>>;
String _$uniqueTagsHash() => r'c3e83713f4f61815506fff9d5d549666b90bcbf6';

/// See also [uniqueTags].
@ProviderFor(uniqueTags)
final uniqueTagsProvider = AutoDisposeFutureProvider<List<String>>.internal(
  uniqueTags,
  name: r'uniqueTagsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uniqueTagsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UniqueTagsRef = AutoDisposeFutureProviderRef<List<String>>;
String _$vaultStatsHash() => r'17dbc9b9f8893ab879c44ad4d83316eea2b5dfa8';

/// See also [vaultStats].
@ProviderFor(vaultStats)
final vaultStatsProvider =
    AutoDisposeFutureProvider<
      ({int totalNotes, int totalWords, int totalLinks})
    >.internal(
      vaultStats,
      name: r'vaultStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$vaultStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VaultStatsRef =
    AutoDisposeFutureProviderRef<
      ({int totalNotes, int totalWords, int totalLinks})
    >;
String _$searchResultsHash() => r'ec2999f61d1d2b4d519f918f56d770629b050c63';

/// See also [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider = AutoDisposeFutureProvider<List<Note>>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsRef = AutoDisposeFutureProviderRef<List<Note>>;
String _$autocompleteSuggestionsHash() =>
    r'575635bd31c64296198a9f0f7e0f2634143aff9f';

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

/// See also [autocompleteSuggestions].
@ProviderFor(autocompleteSuggestions)
const autocompleteSuggestionsProvider = AutocompleteSuggestionsFamily();

/// See also [autocompleteSuggestions].
class AutocompleteSuggestionsFamily extends Family<AsyncValue<List<Note>>> {
  /// See also [autocompleteSuggestions].
  const AutocompleteSuggestionsFamily();

  /// See also [autocompleteSuggestions].
  AutocompleteSuggestionsProvider call(String query) {
    return AutocompleteSuggestionsProvider(query);
  }

  @override
  AutocompleteSuggestionsProvider getProviderOverride(
    covariant AutocompleteSuggestionsProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'autocompleteSuggestionsProvider';
}

/// See also [autocompleteSuggestions].
class AutocompleteSuggestionsProvider
    extends AutoDisposeFutureProvider<List<Note>> {
  /// See also [autocompleteSuggestions].
  AutocompleteSuggestionsProvider(String query)
    : this._internal(
        (ref) =>
            autocompleteSuggestions(ref as AutocompleteSuggestionsRef, query),
        from: autocompleteSuggestionsProvider,
        name: r'autocompleteSuggestionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$autocompleteSuggestionsHash,
        dependencies: AutocompleteSuggestionsFamily._dependencies,
        allTransitiveDependencies:
            AutocompleteSuggestionsFamily._allTransitiveDependencies,
        query: query,
      );

  AutocompleteSuggestionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Note>> Function(AutocompleteSuggestionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AutocompleteSuggestionsProvider._internal(
        (ref) => create(ref as AutocompleteSuggestionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Note>> createElement() {
    return _AutocompleteSuggestionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AutocompleteSuggestionsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AutocompleteSuggestionsRef on AutoDisposeFutureProviderRef<List<Note>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _AutocompleteSuggestionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Note>>
    with AutocompleteSuggestionsRef {
  _AutocompleteSuggestionsProviderElement(super.provider);

  @override
  String get query => (origin as AutocompleteSuggestionsProvider).query;
}

String _$noteByIdHash() => r'e5b942c4b2f416fe5d3019055f00b66f0d310db0';

/// See also [noteById].
@ProviderFor(noteById)
const noteByIdProvider = NoteByIdFamily();

/// See also [noteById].
class NoteByIdFamily extends Family<AsyncValue<Note?>> {
  /// See also [noteById].
  const NoteByIdFamily();

  /// See also [noteById].
  NoteByIdProvider call(String id) {
    return NoteByIdProvider(id);
  }

  @override
  NoteByIdProvider getProviderOverride(covariant NoteByIdProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'noteByIdProvider';
}

/// See also [noteById].
class NoteByIdProvider extends AutoDisposeFutureProvider<Note?> {
  /// See also [noteById].
  NoteByIdProvider(String id)
    : this._internal(
        (ref) => noteById(ref as NoteByIdRef, id),
        from: noteByIdProvider,
        name: r'noteByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$noteByIdHash,
        dependencies: NoteByIdFamily._dependencies,
        allTransitiveDependencies: NoteByIdFamily._allTransitiveDependencies,
        id: id,
      );

  NoteByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(FutureOr<Note?> Function(NoteByIdRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: NoteByIdProvider._internal(
        (ref) => create(ref as NoteByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Note?> createElement() {
    return _NoteByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NoteByIdRef on AutoDisposeFutureProviderRef<Note?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _NoteByIdProviderElement extends AutoDisposeFutureProviderElement<Note?>
    with NoteByIdRef {
  _NoteByIdProviderElement(super.provider);

  @override
  String get id => (origin as NoteByIdProvider).id;
}

String _$backlinksHash() => r'88499bcdf542716a6b58706bd0c5a9d816d88ffa';

/// See also [backlinks].
@ProviderFor(backlinks)
const backlinksProvider = BacklinksFamily();

/// See also [backlinks].
class BacklinksFamily extends Family<AsyncValue<List<Backlink>>> {
  /// See also [backlinks].
  const BacklinksFamily();

  /// See also [backlinks].
  BacklinksProvider call(String noteId) {
    return BacklinksProvider(noteId);
  }

  @override
  BacklinksProvider getProviderOverride(covariant BacklinksProvider provider) {
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
  String? get name => r'backlinksProvider';
}

/// See also [backlinks].
class BacklinksProvider extends AutoDisposeFutureProvider<List<Backlink>> {
  /// See also [backlinks].
  BacklinksProvider(String noteId)
    : this._internal(
        (ref) => backlinks(ref as BacklinksRef, noteId),
        from: backlinksProvider,
        name: r'backlinksProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$backlinksHash,
        dependencies: BacklinksFamily._dependencies,
        allTransitiveDependencies: BacklinksFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  BacklinksProvider._internal(
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
    FutureOr<List<Backlink>> Function(BacklinksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BacklinksProvider._internal(
        (ref) => create(ref as BacklinksRef),
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
  AutoDisposeFutureProviderElement<List<Backlink>> createElement() {
    return _BacklinksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BacklinksProvider && other.noteId == noteId;
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
mixin BacklinksRef on AutoDisposeFutureProviderRef<List<Backlink>> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _BacklinksProviderElement
    extends AutoDisposeFutureProviderElement<List<Backlink>>
    with BacklinksRef {
  _BacklinksProviderElement(super.provider);

  @override
  String get noteId => (origin as BacklinksProvider).noteId;
}

String _$homeScreenDataHash() => r'dd032d992bf29330510f8c799a7fbc191acdd329';

/// See also [homeScreenData].
@ProviderFor(homeScreenData)
final homeScreenDataProvider =
    AutoDisposeProvider<AsyncValue<HomeScreenData>>.internal(
      homeScreenData,
      name: r'homeScreenDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeScreenDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeScreenDataRef = AutoDisposeProviderRef<AsyncValue<HomeScreenData>>;
String _$noteDetailsHash() => r'e7c5f7193943d097eb030a1bd9beb9ec2bdadec2';

/// See also [noteDetails].
@ProviderFor(noteDetails)
const noteDetailsProvider = NoteDetailsFamily();

/// See also [noteDetails].
class NoteDetailsFamily
    extends Family<AsyncValue<({List<String> tags, String snippet})>> {
  /// See also [noteDetails].
  const NoteDetailsFamily();

  /// See also [noteDetails].
  NoteDetailsProvider call(String noteId) {
    return NoteDetailsProvider(noteId);
  }

  @override
  NoteDetailsProvider getProviderOverride(
    covariant NoteDetailsProvider provider,
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
  String? get name => r'noteDetailsProvider';
}

/// See also [noteDetails].
class NoteDetailsProvider
    extends AutoDisposeFutureProvider<({List<String> tags, String snippet})> {
  /// See also [noteDetails].
  NoteDetailsProvider(String noteId)
    : this._internal(
        (ref) => noteDetails(ref as NoteDetailsRef, noteId),
        from: noteDetailsProvider,
        name: r'noteDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$noteDetailsHash,
        dependencies: NoteDetailsFamily._dependencies,
        allTransitiveDependencies: NoteDetailsFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  NoteDetailsProvider._internal(
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
    FutureOr<({List<String> tags, String snippet})> Function(
      NoteDetailsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NoteDetailsProvider._internal(
        (ref) => create(ref as NoteDetailsRef),
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
  AutoDisposeFutureProviderElement<({List<String> tags, String snippet})>
  createElement() {
    return _NoteDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteDetailsProvider && other.noteId == noteId;
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
mixin NoteDetailsRef
    on AutoDisposeFutureProviderRef<({List<String> tags, String snippet})> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _NoteDetailsProviderElement
    extends
        AutoDisposeFutureProviderElement<({List<String> tags, String snippet})>
    with NoteDetailsRef {
  _NoteDetailsProviderElement(super.provider);

  @override
  String get noteId => (origin as NoteDetailsProvider).noteId;
}

String _$activeDesktopNoteIdHash() =>
    r'eb0e4b8f8b07851813dacb9d3d62a47579694561';

/// On wide (desktop) windows the notes list and the editor sit side-by-side.
/// This provider holds the id of the note currently open in the desktop pane.
/// It is completely ignored on mobile — navigation there still uses GoRouter pushes.
///
/// Copied from [ActiveDesktopNoteId].
@ProviderFor(ActiveDesktopNoteId)
final activeDesktopNoteIdProvider =
    AutoDisposeNotifierProvider<ActiveDesktopNoteId, String?>.internal(
      ActiveDesktopNoteId.new,
      name: r'activeDesktopNoteIdProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeDesktopNoteIdHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveDesktopNoteId = AutoDisposeNotifier<String?>;
String _$noteSortNotifierHash() => r'9ce87a6f3fdc9ce4de61676a8005d263b62db7ec';

/// See also [NoteSortNotifier].
@ProviderFor(NoteSortNotifier)
final noteSortNotifierProvider =
    AutoDisposeNotifierProvider<NoteSortNotifier, NoteSort>.internal(
      NoteSortNotifier.new,
      name: r'noteSortNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$noteSortNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NoteSortNotifier = AutoDisposeNotifier<NoteSort>;
String _$selectedTagHash() => r'f633dcd739c0db3ea50de4a7e2129b8192845431';

/// See also [SelectedTag].
@ProviderFor(SelectedTag)
final selectedTagProvider =
    AutoDisposeNotifierProvider<SelectedTag, String?>.internal(
      SelectedTag.new,
      name: r'selectedTagProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedTagHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedTag = AutoDisposeNotifier<String?>;
String _$searchQueryHash() => r'efbb98c331ed0c6ee1298ad98bb41f732ddf9447';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
      SearchQuery.new,
      name: r'searchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
String _$searchFocusHash() => r'38c67f6798cfb4b2fa0772cd85bb3a2564da8ce2';

/// See also [SearchFocus].
@ProviderFor(SearchFocus)
final searchFocusProvider =
    AutoDisposeNotifierProvider<SearchFocus, bool>.internal(
      SearchFocus.new,
      name: r'searchFocusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchFocusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchFocus = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
