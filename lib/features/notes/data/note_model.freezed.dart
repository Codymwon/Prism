// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Note {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;
  int get wordCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get isGhost => throw _privateConstructorUsedError;
  bool get isDaily => throw _privateConstructorUsedError;
  String? get dailyDate => throw _privateConstructorUsedError;
  bool get isConflicted => throw _privateConstructorUsedError;
  String? get originalNoteId => throw _privateConstructorUsedError;
  String get snippet => throw _privateConstructorUsedError;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteCopyWith<Note> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteCopyWith<$Res> {
  factory $NoteCopyWith(Note value, $Res Function(Note) then) =
      _$NoteCopyWithImpl<$Res, Note>;
  @useResult
  $Res call({
    String id,
    String title,
    String filePath,
    int wordCount,
    DateTime createdAt,
    DateTime updatedAt,
    bool isGhost,
    bool isDaily,
    String? dailyDate,
    bool isConflicted,
    String? originalNoteId,
    String snippet,
  });
}

/// @nodoc
class _$NoteCopyWithImpl<$Res, $Val extends Note>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? filePath = null,
    Object? wordCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isGhost = null,
    Object? isDaily = null,
    Object? dailyDate = freezed,
    Object? isConflicted = null,
    Object? originalNoteId = freezed,
    Object? snippet = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            filePath: null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String,
            wordCount: null == wordCount
                ? _value.wordCount
                : wordCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isGhost: null == isGhost
                ? _value.isGhost
                : isGhost // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDaily: null == isDaily
                ? _value.isDaily
                : isDaily // ignore: cast_nullable_to_non_nullable
                      as bool,
            dailyDate: freezed == dailyDate
                ? _value.dailyDate
                : dailyDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            isConflicted: null == isConflicted
                ? _value.isConflicted
                : isConflicted // ignore: cast_nullable_to_non_nullable
                      as bool,
            originalNoteId: freezed == originalNoteId
                ? _value.originalNoteId
                : originalNoteId // ignore: cast_nullable_to_non_nullable
                      as String?,
            snippet: null == snippet
                ? _value.snippet
                : snippet // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteImplCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$$NoteImplCopyWith(
    _$NoteImpl value,
    $Res Function(_$NoteImpl) then,
  ) = __$$NoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String filePath,
    int wordCount,
    DateTime createdAt,
    DateTime updatedAt,
    bool isGhost,
    bool isDaily,
    String? dailyDate,
    bool isConflicted,
    String? originalNoteId,
    String snippet,
  });
}

/// @nodoc
class __$$NoteImplCopyWithImpl<$Res>
    extends _$NoteCopyWithImpl<$Res, _$NoteImpl>
    implements _$$NoteImplCopyWith<$Res> {
  __$$NoteImplCopyWithImpl(_$NoteImpl _value, $Res Function(_$NoteImpl) _then)
    : super(_value, _then);

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? filePath = null,
    Object? wordCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isGhost = null,
    Object? isDaily = null,
    Object? dailyDate = freezed,
    Object? isConflicted = null,
    Object? originalNoteId = freezed,
    Object? snippet = null,
  }) {
    return _then(
      _$NoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
        wordCount: null == wordCount
            ? _value.wordCount
            : wordCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isGhost: null == isGhost
            ? _value.isGhost
            : isGhost // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDaily: null == isDaily
            ? _value.isDaily
            : isDaily // ignore: cast_nullable_to_non_nullable
                  as bool,
        dailyDate: freezed == dailyDate
            ? _value.dailyDate
            : dailyDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        isConflicted: null == isConflicted
            ? _value.isConflicted
            : isConflicted // ignore: cast_nullable_to_non_nullable
                  as bool,
        originalNoteId: freezed == originalNoteId
            ? _value.originalNoteId
            : originalNoteId // ignore: cast_nullable_to_non_nullable
                  as String?,
        snippet: null == snippet
            ? _value.snippet
            : snippet // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NoteImpl extends _Note {
  const _$NoteImpl({
    required this.id,
    required this.title,
    required this.filePath,
    required this.wordCount,
    required this.createdAt,
    required this.updatedAt,
    this.isGhost = false,
    this.isDaily = false,
    this.dailyDate,
    this.isConflicted = false,
    this.originalNoteId,
    this.snippet = '',
  }) : super._();

  @override
  final String id;
  @override
  final String title;
  @override
  final String filePath;
  @override
  final int wordCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool isGhost;
  @override
  @JsonKey()
  final bool isDaily;
  @override
  final String? dailyDate;
  @override
  @JsonKey()
  final bool isConflicted;
  @override
  final String? originalNoteId;
  @override
  @JsonKey()
  final String snippet;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      __$$NoteImplCopyWithImpl<_$NoteImpl>(this, _$identity);
}

abstract class _Note extends Note {
  const factory _Note({
    required final String id,
    required final String title,
    required final String filePath,
    required final int wordCount,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final bool isGhost,
    final bool isDaily,
    final String? dailyDate,
    final bool isConflicted,
    final String? originalNoteId,
    final String snippet,
  }) = _$NoteImpl;
  const _Note._() : super._();

  @override
  String get id;
  @override
  String get title;
  @override
  String get filePath;
  @override
  int get wordCount;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get isGhost;
  @override
  bool get isDaily;
  @override
  String? get dailyDate;
  @override
  bool get isConflicted;
  @override
  String? get originalNoteId;
  @override
  String get snippet;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Backlink {
  String get sourceId => throw _privateConstructorUsedError;
  String get sourceTitle => throw _privateConstructorUsedError;
  String? get contextSnippet => throw _privateConstructorUsedError;

  /// Create a copy of Backlink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BacklinkCopyWith<Backlink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BacklinkCopyWith<$Res> {
  factory $BacklinkCopyWith(Backlink value, $Res Function(Backlink) then) =
      _$BacklinkCopyWithImpl<$Res, Backlink>;
  @useResult
  $Res call({String sourceId, String sourceTitle, String? contextSnippet});
}

/// @nodoc
class _$BacklinkCopyWithImpl<$Res, $Val extends Backlink>
    implements $BacklinkCopyWith<$Res> {
  _$BacklinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Backlink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceId = null,
    Object? sourceTitle = null,
    Object? contextSnippet = freezed,
  }) {
    return _then(
      _value.copyWith(
            sourceId: null == sourceId
                ? _value.sourceId
                : sourceId // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceTitle: null == sourceTitle
                ? _value.sourceTitle
                : sourceTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            contextSnippet: freezed == contextSnippet
                ? _value.contextSnippet
                : contextSnippet // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BacklinkImplCopyWith<$Res>
    implements $BacklinkCopyWith<$Res> {
  factory _$$BacklinkImplCopyWith(
    _$BacklinkImpl value,
    $Res Function(_$BacklinkImpl) then,
  ) = __$$BacklinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String sourceId, String sourceTitle, String? contextSnippet});
}

/// @nodoc
class __$$BacklinkImplCopyWithImpl<$Res>
    extends _$BacklinkCopyWithImpl<$Res, _$BacklinkImpl>
    implements _$$BacklinkImplCopyWith<$Res> {
  __$$BacklinkImplCopyWithImpl(
    _$BacklinkImpl _value,
    $Res Function(_$BacklinkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Backlink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceId = null,
    Object? sourceTitle = null,
    Object? contextSnippet = freezed,
  }) {
    return _then(
      _$BacklinkImpl(
        sourceId: null == sourceId
            ? _value.sourceId
            : sourceId // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceTitle: null == sourceTitle
            ? _value.sourceTitle
            : sourceTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        contextSnippet: freezed == contextSnippet
            ? _value.contextSnippet
            : contextSnippet // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$BacklinkImpl implements _Backlink {
  const _$BacklinkImpl({
    required this.sourceId,
    required this.sourceTitle,
    this.contextSnippet,
  });

  @override
  final String sourceId;
  @override
  final String sourceTitle;
  @override
  final String? contextSnippet;

  @override
  String toString() {
    return 'Backlink(sourceId: $sourceId, sourceTitle: $sourceTitle, contextSnippet: $contextSnippet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BacklinkImpl &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.sourceTitle, sourceTitle) ||
                other.sourceTitle == sourceTitle) &&
            (identical(other.contextSnippet, contextSnippet) ||
                other.contextSnippet == contextSnippet));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, sourceId, sourceTitle, contextSnippet);

  /// Create a copy of Backlink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BacklinkImplCopyWith<_$BacklinkImpl> get copyWith =>
      __$$BacklinkImplCopyWithImpl<_$BacklinkImpl>(this, _$identity);
}

abstract class _Backlink implements Backlink {
  const factory _Backlink({
    required final String sourceId,
    required final String sourceTitle,
    final String? contextSnippet,
  }) = _$BacklinkImpl;

  @override
  String get sourceId;
  @override
  String get sourceTitle;
  @override
  String? get contextSnippet;

  /// Create a copy of Backlink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BacklinkImplCopyWith<_$BacklinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
