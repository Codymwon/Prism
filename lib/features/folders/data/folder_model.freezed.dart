// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VirtualFolder {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get colorHex => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  int get noteCount => throw _privateConstructorUsedError;

  /// Create a copy of VirtualFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VirtualFolderCopyWith<VirtualFolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VirtualFolderCopyWith<$Res> {
  factory $VirtualFolderCopyWith(
    VirtualFolder value,
    $Res Function(VirtualFolder) then,
  ) = _$VirtualFolderCopyWithImpl<$Res, VirtualFolder>;
  @useResult
  $Res call({
    String id,
    String name,
    String colorHex,
    String icon,
    DateTime createdAt,
    int sortOrder,
    int noteCount,
  });
}

/// @nodoc
class _$VirtualFolderCopyWithImpl<$Res, $Val extends VirtualFolder>
    implements $VirtualFolderCopyWith<$Res> {
  _$VirtualFolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VirtualFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorHex = null,
    Object? icon = null,
    Object? createdAt = null,
    Object? sortOrder = null,
    Object? noteCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            colorHex: null == colorHex
                ? _value.colorHex
                : colorHex // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            noteCount: null == noteCount
                ? _value.noteCount
                : noteCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VirtualFolderImplCopyWith<$Res>
    implements $VirtualFolderCopyWith<$Res> {
  factory _$$VirtualFolderImplCopyWith(
    _$VirtualFolderImpl value,
    $Res Function(_$VirtualFolderImpl) then,
  ) = __$$VirtualFolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String colorHex,
    String icon,
    DateTime createdAt,
    int sortOrder,
    int noteCount,
  });
}

/// @nodoc
class __$$VirtualFolderImplCopyWithImpl<$Res>
    extends _$VirtualFolderCopyWithImpl<$Res, _$VirtualFolderImpl>
    implements _$$VirtualFolderImplCopyWith<$Res> {
  __$$VirtualFolderImplCopyWithImpl(
    _$VirtualFolderImpl _value,
    $Res Function(_$VirtualFolderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VirtualFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorHex = null,
    Object? icon = null,
    Object? createdAt = null,
    Object? sortOrder = null,
    Object? noteCount = null,
  }) {
    return _then(
      _$VirtualFolderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        colorHex: null == colorHex
            ? _value.colorHex
            : colorHex // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        noteCount: null == noteCount
            ? _value.noteCount
            : noteCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$VirtualFolderImpl extends _VirtualFolder {
  const _$VirtualFolderImpl({
    required this.id,
    required this.name,
    this.colorHex = '#7C6FF7',
    this.icon = 'folder',
    required this.createdAt,
    required this.sortOrder,
    this.noteCount = 0,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String colorHex;
  @override
  @JsonKey()
  final String icon;
  @override
  final DateTime createdAt;
  @override
  final int sortOrder;
  @override
  @JsonKey()
  final int noteCount;

  /// Create a copy of VirtualFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VirtualFolderImplCopyWith<_$VirtualFolderImpl> get copyWith =>
      __$$VirtualFolderImplCopyWithImpl<_$VirtualFolderImpl>(this, _$identity);
}

abstract class _VirtualFolder extends VirtualFolder {
  const factory _VirtualFolder({
    required final String id,
    required final String name,
    final String colorHex,
    final String icon,
    required final DateTime createdAt,
    required final int sortOrder,
    final int noteCount,
  }) = _$VirtualFolderImpl;
  const _VirtualFolder._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get colorHex;
  @override
  String get icon;
  @override
  DateTime get createdAt;
  @override
  int get sortOrder;
  @override
  int get noteCount;

  /// Create a copy of VirtualFolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VirtualFolderImplCopyWith<_$VirtualFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
