// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webview_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebviewState {

 String get currentUrl; bool get isLoading; bool get canGoBack; bool get canGoForward; String? get error; List<String> get navigationHistory;
/// Create a copy of WebviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebviewStateCopyWith<WebviewState> get copyWith => _$WebviewStateCopyWithImpl<WebviewState>(this as WebviewState, _$identity);

  /// Serializes this WebviewState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebviewState&&(identical(other.currentUrl, currentUrl) || other.currentUrl == currentUrl)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.canGoBack, canGoBack) || other.canGoBack == canGoBack)&&(identical(other.canGoForward, canGoForward) || other.canGoForward == canGoForward)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.navigationHistory, navigationHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentUrl,isLoading,canGoBack,canGoForward,error,const DeepCollectionEquality().hash(navigationHistory));

@override
String toString() {
  return 'WebviewState(currentUrl: $currentUrl, isLoading: $isLoading, canGoBack: $canGoBack, canGoForward: $canGoForward, error: $error, navigationHistory: $navigationHistory)';
}


}

/// @nodoc
abstract mixin class $WebviewStateCopyWith<$Res>  {
  factory $WebviewStateCopyWith(WebviewState value, $Res Function(WebviewState) _then) = _$WebviewStateCopyWithImpl;
@useResult
$Res call({
 String currentUrl, bool isLoading, bool canGoBack, bool canGoForward, String? error, List<String> navigationHistory
});




}
/// @nodoc
class _$WebviewStateCopyWithImpl<$Res>
    implements $WebviewStateCopyWith<$Res> {
  _$WebviewStateCopyWithImpl(this._self, this._then);

  final WebviewState _self;
  final $Res Function(WebviewState) _then;

/// Create a copy of WebviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentUrl = null,Object? isLoading = null,Object? canGoBack = null,Object? canGoForward = null,Object? error = freezed,Object? navigationHistory = null,}) {
  return _then(_self.copyWith(
currentUrl: null == currentUrl ? _self.currentUrl : currentUrl // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,canGoBack: null == canGoBack ? _self.canGoBack : canGoBack // ignore: cast_nullable_to_non_nullable
as bool,canGoForward: null == canGoForward ? _self.canGoForward : canGoForward // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,navigationHistory: null == navigationHistory ? _self.navigationHistory : navigationHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WebviewState].
extension WebviewStatePatterns on WebviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebviewState value)  $default,){
final _that = this;
switch (_that) {
case _WebviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebviewState value)?  $default,){
final _that = this;
switch (_that) {
case _WebviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currentUrl,  bool isLoading,  bool canGoBack,  bool canGoForward,  String? error,  List<String> navigationHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebviewState() when $default != null:
return $default(_that.currentUrl,_that.isLoading,_that.canGoBack,_that.canGoForward,_that.error,_that.navigationHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currentUrl,  bool isLoading,  bool canGoBack,  bool canGoForward,  String? error,  List<String> navigationHistory)  $default,) {final _that = this;
switch (_that) {
case _WebviewState():
return $default(_that.currentUrl,_that.isLoading,_that.canGoBack,_that.canGoForward,_that.error,_that.navigationHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currentUrl,  bool isLoading,  bool canGoBack,  bool canGoForward,  String? error,  List<String> navigationHistory)?  $default,) {final _that = this;
switch (_that) {
case _WebviewState() when $default != null:
return $default(_that.currentUrl,_that.isLoading,_that.canGoBack,_that.canGoForward,_that.error,_that.navigationHistory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebviewState implements WebviewState {
  const _WebviewState({this.currentUrl = '', this.isLoading = false, this.canGoBack = false, this.canGoForward = false, this.error, final  List<String> navigationHistory = const []}): _navigationHistory = navigationHistory;
  factory _WebviewState.fromJson(Map<String, dynamic> json) => _$WebviewStateFromJson(json);

@override@JsonKey() final  String currentUrl;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool canGoBack;
@override@JsonKey() final  bool canGoForward;
@override final  String? error;
 final  List<String> _navigationHistory;
@override@JsonKey() List<String> get navigationHistory {
  if (_navigationHistory is EqualUnmodifiableListView) return _navigationHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_navigationHistory);
}


/// Create a copy of WebviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebviewStateCopyWith<_WebviewState> get copyWith => __$WebviewStateCopyWithImpl<_WebviewState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebviewStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebviewState&&(identical(other.currentUrl, currentUrl) || other.currentUrl == currentUrl)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.canGoBack, canGoBack) || other.canGoBack == canGoBack)&&(identical(other.canGoForward, canGoForward) || other.canGoForward == canGoForward)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._navigationHistory, _navigationHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentUrl,isLoading,canGoBack,canGoForward,error,const DeepCollectionEquality().hash(_navigationHistory));

@override
String toString() {
  return 'WebviewState(currentUrl: $currentUrl, isLoading: $isLoading, canGoBack: $canGoBack, canGoForward: $canGoForward, error: $error, navigationHistory: $navigationHistory)';
}


}

/// @nodoc
abstract mixin class _$WebviewStateCopyWith<$Res> implements $WebviewStateCopyWith<$Res> {
  factory _$WebviewStateCopyWith(_WebviewState value, $Res Function(_WebviewState) _then) = __$WebviewStateCopyWithImpl;
@override @useResult
$Res call({
 String currentUrl, bool isLoading, bool canGoBack, bool canGoForward, String? error, List<String> navigationHistory
});




}
/// @nodoc
class __$WebviewStateCopyWithImpl<$Res>
    implements _$WebviewStateCopyWith<$Res> {
  __$WebviewStateCopyWithImpl(this._self, this._then);

  final _WebviewState _self;
  final $Res Function(_WebviewState) _then;

/// Create a copy of WebviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentUrl = null,Object? isLoading = null,Object? canGoBack = null,Object? canGoForward = null,Object? error = freezed,Object? navigationHistory = null,}) {
  return _then(_WebviewState(
currentUrl: null == currentUrl ? _self.currentUrl : currentUrl // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,canGoBack: null == canGoBack ? _self.canGoBack : canGoBack // ignore: cast_nullable_to_non_nullable
as bool,canGoForward: null == canGoForward ? _self.canGoForward : canGoForward // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,navigationHistory: null == navigationHistory ? _self._navigationHistory : navigationHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
