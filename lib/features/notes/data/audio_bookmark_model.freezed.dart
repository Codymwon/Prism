// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_bookmark_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AudioBookmark {
  String get id => throw _privateConstructorUsedError;
  String get noteId => throw _privateConstructorUsedError;
  String get attachmentPath => throw _privateConstructorUsedError;
  int get timestampMs => throw _privateConstructorUsedError;
  String get annotationText => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of AudioBookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AudioBookmarkCopyWith<AudioBookmark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioBookmarkCopyWith<$Res> {
  factory $AudioBookmarkCopyWith(
    AudioBookmark value,
    $Res Function(AudioBookmark) then,
  ) = _$AudioBookmarkCopyWithImpl<$Res, AudioBookmark>;
  @useResult
  $Res call({
    String id,
    String noteId,
    String attachmentPath,
    int timestampMs,
    String annotationText,
    DateTime createdAt,
  });
}

/// @nodoc
class _$AudioBookmarkCopyWithImpl<$Res, $Val extends AudioBookmark>
    implements $AudioBookmarkCopyWith<$Res> {
  _$AudioBookmarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioBookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? noteId = null,
    Object? attachmentPath = null,
    Object? timestampMs = null,
    Object? annotationText = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            noteId: null == noteId
                ? _value.noteId
                : noteId // ignore: cast_nullable_to_non_nullable
                      as String,
            attachmentPath: null == attachmentPath
                ? _value.attachmentPath
                : attachmentPath // ignore: cast_nullable_to_non_nullable
                      as String,
            timestampMs: null == timestampMs
                ? _value.timestampMs
                : timestampMs // ignore: cast_nullable_to_non_nullable
                      as int,
            annotationText: null == annotationText
                ? _value.annotationText
                : annotationText // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AudioBookmarkImplCopyWith<$Res>
    implements $AudioBookmarkCopyWith<$Res> {
  factory _$$AudioBookmarkImplCopyWith(
    _$AudioBookmarkImpl value,
    $Res Function(_$AudioBookmarkImpl) then,
  ) = __$$AudioBookmarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String noteId,
    String attachmentPath,
    int timestampMs,
    String annotationText,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$AudioBookmarkImplCopyWithImpl<$Res>
    extends _$AudioBookmarkCopyWithImpl<$Res, _$AudioBookmarkImpl>
    implements _$$AudioBookmarkImplCopyWith<$Res> {
  __$$AudioBookmarkImplCopyWithImpl(
    _$AudioBookmarkImpl _value,
    $Res Function(_$AudioBookmarkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioBookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? noteId = null,
    Object? attachmentPath = null,
    Object? timestampMs = null,
    Object? annotationText = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AudioBookmarkImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        noteId: null == noteId
            ? _value.noteId
            : noteId // ignore: cast_nullable_to_non_nullable
                  as String,
        attachmentPath: null == attachmentPath
            ? _value.attachmentPath
            : attachmentPath // ignore: cast_nullable_to_non_nullable
                  as String,
        timestampMs: null == timestampMs
            ? _value.timestampMs
            : timestampMs // ignore: cast_nullable_to_non_nullable
                  as int,
        annotationText: null == annotationText
            ? _value.annotationText
            : annotationText // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$AudioBookmarkImpl extends _AudioBookmark {
  const _$AudioBookmarkImpl({
    required this.id,
    required this.noteId,
    required this.attachmentPath,
    required this.timestampMs,
    required this.annotationText,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String noteId;
  @override
  final String attachmentPath;
  @override
  final int timestampMs;
  @override
  final String annotationText;
  @override
  final DateTime createdAt;

  /// Create a copy of AudioBookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioBookmarkImplCopyWith<_$AudioBookmarkImpl> get copyWith =>
      __$$AudioBookmarkImplCopyWithImpl<_$AudioBookmarkImpl>(this, _$identity);
}

abstract class _AudioBookmark extends AudioBookmark {
  const factory _AudioBookmark({
    required final String id,
    required final String noteId,
    required final String attachmentPath,
    required final int timestampMs,
    required final String annotationText,
    required final DateTime createdAt,
  }) = _$AudioBookmarkImpl;
  const _AudioBookmark._() : super._();

  @override
  String get id;
  @override
  String get noteId;
  @override
  String get attachmentPath;
  @override
  int get timestampMs;
  @override
  String get annotationText;
  @override
  DateTime get createdAt;

  /// Create a copy of AudioBookmark
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioBookmarkImplCopyWith<_$AudioBookmarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
