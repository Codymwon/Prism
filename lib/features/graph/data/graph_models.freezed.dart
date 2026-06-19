// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GraphNodePosition {
  String get noteId => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;

  /// Create a copy of GraphNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GraphNodePositionCopyWith<GraphNodePosition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GraphNodePositionCopyWith<$Res> {
  factory $GraphNodePositionCopyWith(
    GraphNodePosition value,
    $Res Function(GraphNodePosition) then,
  ) = _$GraphNodePositionCopyWithImpl<$Res, GraphNodePosition>;
  @useResult
  $Res call({String noteId, double x, double y, bool isPinned});
}

/// @nodoc
class _$GraphNodePositionCopyWithImpl<$Res, $Val extends GraphNodePosition>
    implements $GraphNodePositionCopyWith<$Res> {
  _$GraphNodePositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GraphNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? x = null,
    Object? y = null,
    Object? isPinned = null,
  }) {
    return _then(
      _value.copyWith(
            noteId: null == noteId
                ? _value.noteId
                : noteId // ignore: cast_nullable_to_non_nullable
                      as String,
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GraphNodePositionImplCopyWith<$Res>
    implements $GraphNodePositionCopyWith<$Res> {
  factory _$$GraphNodePositionImplCopyWith(
    _$GraphNodePositionImpl value,
    $Res Function(_$GraphNodePositionImpl) then,
  ) = __$$GraphNodePositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String noteId, double x, double y, bool isPinned});
}

/// @nodoc
class __$$GraphNodePositionImplCopyWithImpl<$Res>
    extends _$GraphNodePositionCopyWithImpl<$Res, _$GraphNodePositionImpl>
    implements _$$GraphNodePositionImplCopyWith<$Res> {
  __$$GraphNodePositionImplCopyWithImpl(
    _$GraphNodePositionImpl _value,
    $Res Function(_$GraphNodePositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GraphNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? x = null,
    Object? y = null,
    Object? isPinned = null,
  }) {
    return _then(
      _$GraphNodePositionImpl(
        noteId: null == noteId
            ? _value.noteId
            : noteId // ignore: cast_nullable_to_non_nullable
                  as String,
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$GraphNodePositionImpl extends _GraphNodePosition {
  const _$GraphNodePositionImpl({
    required this.noteId,
    required this.x,
    required this.y,
    this.isPinned = false,
  }) : super._();

  @override
  final String noteId;
  @override
  final double x;
  @override
  final double y;
  @override
  @JsonKey()
  final bool isPinned;

  /// Create a copy of GraphNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GraphNodePositionImplCopyWith<_$GraphNodePositionImpl> get copyWith =>
      __$$GraphNodePositionImplCopyWithImpl<_$GraphNodePositionImpl>(
        this,
        _$identity,
      );
}

abstract class _GraphNodePosition extends GraphNodePosition {
  const factory _GraphNodePosition({
    required final String noteId,
    required final double x,
    required final double y,
    final bool isPinned,
  }) = _$GraphNodePositionImpl;
  const _GraphNodePosition._() : super._();

  @override
  String get noteId;
  @override
  double get x;
  @override
  double get y;
  @override
  bool get isPinned;

  /// Create a copy of GraphNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GraphNodePositionImplCopyWith<_$GraphNodePositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
