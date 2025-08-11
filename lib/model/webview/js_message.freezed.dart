// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'js_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JSMessage {

 String get type; Map<String, dynamic> get data; String? get id; DateTime? get timestamp;
/// Create a copy of JSMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JSMessageCopyWith<JSMessage> get copyWith => _$JSMessageCopyWithImpl<JSMessage>(this as JSMessage, _$identity);

  /// Serializes this JSMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JSMessage&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(data),id,timestamp);

@override
String toString() {
  return 'JSMessage(type: $type, data: $data, id: $id, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $JSMessageCopyWith<$Res>  {
  factory $JSMessageCopyWith(JSMessage value, $Res Function(JSMessage) _then) = _$JSMessageCopyWithImpl;
@useResult
$Res call({
 String type, Map<String, dynamic> data, String? id, DateTime? timestamp
});




}
/// @nodoc
class _$JSMessageCopyWithImpl<$Res>
    implements $JSMessageCopyWith<$Res> {
  _$JSMessageCopyWithImpl(this._self, this._then);

  final JSMessage _self;
  final $Res Function(JSMessage) _then;

/// Create a copy of JSMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? data = null,Object? id = freezed,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [JSMessage].
extension JSMessagePatterns on JSMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JSMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JSMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JSMessage value)  $default,){
final _that = this;
switch (_that) {
case _JSMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JSMessage value)?  $default,){
final _that = this;
switch (_that) {
case _JSMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic> data,  String? id,  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JSMessage() when $default != null:
return $default(_that.type,_that.data,_that.id,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic> data,  String? id,  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _JSMessage():
return $default(_that.type,_that.data,_that.id,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  Map<String, dynamic> data,  String? id,  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _JSMessage() when $default != null:
return $default(_that.type,_that.data,_that.id,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JSMessage implements JSMessage {
  const _JSMessage({required this.type, required final  Map<String, dynamic> data, this.id, this.timestamp}): _data = data;
  factory _JSMessage.fromJson(Map<String, dynamic> json) => _$JSMessageFromJson(json);

@override final  String type;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  String? id;
@override final  DateTime? timestamp;

/// Create a copy of JSMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JSMessageCopyWith<_JSMessage> get copyWith => __$JSMessageCopyWithImpl<_JSMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JSMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JSMessage&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_data),id,timestamp);

@override
String toString() {
  return 'JSMessage(type: $type, data: $data, id: $id, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$JSMessageCopyWith<$Res> implements $JSMessageCopyWith<$Res> {
  factory _$JSMessageCopyWith(_JSMessage value, $Res Function(_JSMessage) _then) = __$JSMessageCopyWithImpl;
@override @useResult
$Res call({
 String type, Map<String, dynamic> data, String? id, DateTime? timestamp
});




}
/// @nodoc
class __$JSMessageCopyWithImpl<$Res>
    implements _$JSMessageCopyWith<$Res> {
  __$JSMessageCopyWithImpl(this._self, this._then);

  final _JSMessage _self;
  final $Res Function(_JSMessage) _then;

/// Create a copy of JSMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? data = null,Object? id = freezed,Object? timestamp = freezed,}) {
  return _then(_JSMessage(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
