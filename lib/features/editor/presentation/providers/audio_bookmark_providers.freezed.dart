// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_bookmark_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookmarkKey {
  String get noteId => throw _privateConstructorUsedError;
  String get attachmentPath => throw _privateConstructorUsedError;

  /// Create a copy of BookmarkKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookmarkKeyCopyWith<BookmarkKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookmarkKeyCopyWith<$Res> {
  factory $BookmarkKeyCopyWith(
    BookmarkKey value,
    $Res Function(BookmarkKey) then,
  ) = _$BookmarkKeyCopyWithImpl<$Res, BookmarkKey>;
  @useResult
  $Res call({String noteId, String attachmentPath});
}

/// @nodoc
class _$BookmarkKeyCopyWithImpl<$Res, $Val extends BookmarkKey>
    implements $BookmarkKeyCopyWith<$Res> {
  _$BookmarkKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookmarkKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? noteId = null, Object? attachmentPath = null}) {
    return _then(
      _value.copyWith(
            noteId: null == noteId
                ? _value.noteId
                : noteId // ignore: cast_nullable_to_non_nullable
                      as String,
            attachmentPath: null == attachmentPath
                ? _value.attachmentPath
                : attachmentPath // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookmarkKeyImplCopyWith<$Res>
    implements $BookmarkKeyCopyWith<$Res> {
  factory _$$BookmarkKeyImplCopyWith(
    _$BookmarkKeyImpl value,
    $Res Function(_$BookmarkKeyImpl) then,
  ) = __$$BookmarkKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String noteId, String attachmentPath});
}

/// @nodoc
class __$$BookmarkKeyImplCopyWithImpl<$Res>
    extends _$BookmarkKeyCopyWithImpl<$Res, _$BookmarkKeyImpl>
    implements _$$BookmarkKeyImplCopyWith<$Res> {
  __$$BookmarkKeyImplCopyWithImpl(
    _$BookmarkKeyImpl _value,
    $Res Function(_$BookmarkKeyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookmarkKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? noteId = null, Object? attachmentPath = null}) {
    return _then(
      _$BookmarkKeyImpl(
        noteId: null == noteId
            ? _value.noteId
            : noteId // ignore: cast_nullable_to_non_nullable
                  as String,
        attachmentPath: null == attachmentPath
            ? _value.attachmentPath
            : attachmentPath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$BookmarkKeyImpl with DiagnosticableTreeMixin implements _BookmarkKey {
  const _$BookmarkKeyImpl({required this.noteId, required this.attachmentPath});

  @override
  final String noteId;
  @override
  final String attachmentPath;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BookmarkKey(noteId: $noteId, attachmentPath: $attachmentPath)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'BookmarkKey'))
      ..add(DiagnosticsProperty('noteId', noteId))
      ..add(DiagnosticsProperty('attachmentPath', attachmentPath));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookmarkKeyImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            (identical(other.attachmentPath, attachmentPath) ||
                other.attachmentPath == attachmentPath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId, attachmentPath);

  /// Create a copy of BookmarkKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookmarkKeyImplCopyWith<_$BookmarkKeyImpl> get copyWith =>
      __$$BookmarkKeyImplCopyWithImpl<_$BookmarkKeyImpl>(this, _$identity);
}

abstract class _BookmarkKey implements BookmarkKey {
  const factory _BookmarkKey({
    required final String noteId,
    required final String attachmentPath,
  }) = _$BookmarkKeyImpl;

  @override
  String get noteId;
  @override
  String get attachmentPath;

  /// Create a copy of BookmarkKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookmarkKeyImplCopyWith<_$BookmarkKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AudioBookmarkState {
  List<AudioBookmark> get bookmarks => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of AudioBookmarkState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AudioBookmarkStateCopyWith<AudioBookmarkState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioBookmarkStateCopyWith<$Res> {
  factory $AudioBookmarkStateCopyWith(
    AudioBookmarkState value,
    $Res Function(AudioBookmarkState) then,
  ) = _$AudioBookmarkStateCopyWithImpl<$Res, AudioBookmarkState>;
  @useResult
  $Res call({List<AudioBookmark> bookmarks, bool isLoading, String? error});
}

/// @nodoc
class _$AudioBookmarkStateCopyWithImpl<$Res, $Val extends AudioBookmarkState>
    implements $AudioBookmarkStateCopyWith<$Res> {
  _$AudioBookmarkStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioBookmarkState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookmarks = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            bookmarks: null == bookmarks
                ? _value.bookmarks
                : bookmarks // ignore: cast_nullable_to_non_nullable
                      as List<AudioBookmark>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AudioBookmarkStateImplCopyWith<$Res>
    implements $AudioBookmarkStateCopyWith<$Res> {
  factory _$$AudioBookmarkStateImplCopyWith(
    _$AudioBookmarkStateImpl value,
    $Res Function(_$AudioBookmarkStateImpl) then,
  ) = __$$AudioBookmarkStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AudioBookmark> bookmarks, bool isLoading, String? error});
}

/// @nodoc
class __$$AudioBookmarkStateImplCopyWithImpl<$Res>
    extends _$AudioBookmarkStateCopyWithImpl<$Res, _$AudioBookmarkStateImpl>
    implements _$$AudioBookmarkStateImplCopyWith<$Res> {
  __$$AudioBookmarkStateImplCopyWithImpl(
    _$AudioBookmarkStateImpl _value,
    $Res Function(_$AudioBookmarkStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioBookmarkState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookmarks = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$AudioBookmarkStateImpl(
        bookmarks: null == bookmarks
            ? _value._bookmarks
            : bookmarks // ignore: cast_nullable_to_non_nullable
                  as List<AudioBookmark>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AudioBookmarkStateImpl
    with DiagnosticableTreeMixin
    implements _AudioBookmarkState {
  const _$AudioBookmarkStateImpl({
    final List<AudioBookmark> bookmarks = const [],
    this.isLoading = false,
    this.error,
  }) : _bookmarks = bookmarks;

  final List<AudioBookmark> _bookmarks;
  @override
  @JsonKey()
  List<AudioBookmark> get bookmarks {
    if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarks);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'AudioBookmarkState(bookmarks: $bookmarks, isLoading: $isLoading, error: $error)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'AudioBookmarkState'))
      ..add(DiagnosticsProperty('bookmarks', bookmarks))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioBookmarkStateImpl &&
            const DeepCollectionEquality().equals(
              other._bookmarks,
              _bookmarks,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_bookmarks),
    isLoading,
    error,
  );

  /// Create a copy of AudioBookmarkState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioBookmarkStateImplCopyWith<_$AudioBookmarkStateImpl> get copyWith =>
      __$$AudioBookmarkStateImplCopyWithImpl<_$AudioBookmarkStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AudioBookmarkState implements AudioBookmarkState {
  const factory _AudioBookmarkState({
    final List<AudioBookmark> bookmarks,
    final bool isLoading,
    final String? error,
  }) = _$AudioBookmarkStateImpl;

  @override
  List<AudioBookmark> get bookmarks;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of AudioBookmarkState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioBookmarkStateImplCopyWith<_$AudioBookmarkStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
