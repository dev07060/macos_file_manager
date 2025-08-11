// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webview_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebviewConfig {

/// Initial URL to load when webview starts. Defaults to Google.com.
 String get initialUrl;/// Whether JavaScript execution is enabled in the webview.
 bool get javascriptEnabled;/// Whether debugging features are enabled for development.
 bool get debuggingEnabled;/// Custom user agent string for the webview.
 String get userAgent;/// Timeout for initial URL loading in seconds.
 int get initialLoadTimeoutSeconds;/// Whether to automatically load the initial URL on webview creation.
 bool get autoLoadInitialUrl;
/// Create a copy of WebviewConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebviewConfigCopyWith<WebviewConfig> get copyWith => _$WebviewConfigCopyWithImpl<WebviewConfig>(this as WebviewConfig, _$identity);

  /// Serializes this WebviewConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebviewConfig&&(identical(other.initialUrl, initialUrl) || other.initialUrl == initialUrl)&&(identical(other.javascriptEnabled, javascriptEnabled) || other.javascriptEnabled == javascriptEnabled)&&(identical(other.debuggingEnabled, debuggingEnabled) || other.debuggingEnabled == debuggingEnabled)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.initialLoadTimeoutSeconds, initialLoadTimeoutSeconds) || other.initialLoadTimeoutSeconds == initialLoadTimeoutSeconds)&&(identical(other.autoLoadInitialUrl, autoLoadInitialUrl) || other.autoLoadInitialUrl == autoLoadInitialUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,initialUrl,javascriptEnabled,debuggingEnabled,userAgent,initialLoadTimeoutSeconds,autoLoadInitialUrl);

@override
String toString() {
  return 'WebviewConfig(initialUrl: $initialUrl, javascriptEnabled: $javascriptEnabled, debuggingEnabled: $debuggingEnabled, userAgent: $userAgent, initialLoadTimeoutSeconds: $initialLoadTimeoutSeconds, autoLoadInitialUrl: $autoLoadInitialUrl)';
}


}

/// @nodoc
abstract mixin class $WebviewConfigCopyWith<$Res>  {
  factory $WebviewConfigCopyWith(WebviewConfig value, $Res Function(WebviewConfig) _then) = _$WebviewConfigCopyWithImpl;
@useResult
$Res call({
 String initialUrl, bool javascriptEnabled, bool debuggingEnabled, String userAgent, int initialLoadTimeoutSeconds, bool autoLoadInitialUrl
});




}
/// @nodoc
class _$WebviewConfigCopyWithImpl<$Res>
    implements $WebviewConfigCopyWith<$Res> {
  _$WebviewConfigCopyWithImpl(this._self, this._then);

  final WebviewConfig _self;
  final $Res Function(WebviewConfig) _then;

/// Create a copy of WebviewConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? initialUrl = null,Object? javascriptEnabled = null,Object? debuggingEnabled = null,Object? userAgent = null,Object? initialLoadTimeoutSeconds = null,Object? autoLoadInitialUrl = null,}) {
  return _then(_self.copyWith(
initialUrl: null == initialUrl ? _self.initialUrl : initialUrl // ignore: cast_nullable_to_non_nullable
as String,javascriptEnabled: null == javascriptEnabled ? _self.javascriptEnabled : javascriptEnabled // ignore: cast_nullable_to_non_nullable
as bool,debuggingEnabled: null == debuggingEnabled ? _self.debuggingEnabled : debuggingEnabled // ignore: cast_nullable_to_non_nullable
as bool,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,initialLoadTimeoutSeconds: null == initialLoadTimeoutSeconds ? _self.initialLoadTimeoutSeconds : initialLoadTimeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,autoLoadInitialUrl: null == autoLoadInitialUrl ? _self.autoLoadInitialUrl : autoLoadInitialUrl // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WebviewConfig].
extension WebviewConfigPatterns on WebviewConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebviewConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebviewConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebviewConfig value)  $default,){
final _that = this;
switch (_that) {
case _WebviewConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebviewConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WebviewConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String initialUrl,  bool javascriptEnabled,  bool debuggingEnabled,  String userAgent,  int initialLoadTimeoutSeconds,  bool autoLoadInitialUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebviewConfig() when $default != null:
return $default(_that.initialUrl,_that.javascriptEnabled,_that.debuggingEnabled,_that.userAgent,_that.initialLoadTimeoutSeconds,_that.autoLoadInitialUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String initialUrl,  bool javascriptEnabled,  bool debuggingEnabled,  String userAgent,  int initialLoadTimeoutSeconds,  bool autoLoadInitialUrl)  $default,) {final _that = this;
switch (_that) {
case _WebviewConfig():
return $default(_that.initialUrl,_that.javascriptEnabled,_that.debuggingEnabled,_that.userAgent,_that.initialLoadTimeoutSeconds,_that.autoLoadInitialUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String initialUrl,  bool javascriptEnabled,  bool debuggingEnabled,  String userAgent,  int initialLoadTimeoutSeconds,  bool autoLoadInitialUrl)?  $default,) {final _that = this;
switch (_that) {
case _WebviewConfig() when $default != null:
return $default(_that.initialUrl,_that.javascriptEnabled,_that.debuggingEnabled,_that.userAgent,_that.initialLoadTimeoutSeconds,_that.autoLoadInitialUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebviewConfig implements WebviewConfig {
  const _WebviewConfig({this.initialUrl = 'https://www.google.com', this.javascriptEnabled = true, this.debuggingEnabled = true, this.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Flutter WebView', this.initialLoadTimeoutSeconds = 30, this.autoLoadInitialUrl = true});
  factory _WebviewConfig.fromJson(Map<String, dynamic> json) => _$WebviewConfigFromJson(json);

/// Initial URL to load when webview starts. Defaults to Google.com.
@override@JsonKey() final  String initialUrl;
/// Whether JavaScript execution is enabled in the webview.
@override@JsonKey() final  bool javascriptEnabled;
/// Whether debugging features are enabled for development.
@override@JsonKey() final  bool debuggingEnabled;
/// Custom user agent string for the webview.
@override@JsonKey() final  String userAgent;
/// Timeout for initial URL loading in seconds.
@override@JsonKey() final  int initialLoadTimeoutSeconds;
/// Whether to automatically load the initial URL on webview creation.
@override@JsonKey() final  bool autoLoadInitialUrl;

/// Create a copy of WebviewConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebviewConfigCopyWith<_WebviewConfig> get copyWith => __$WebviewConfigCopyWithImpl<_WebviewConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebviewConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebviewConfig&&(identical(other.initialUrl, initialUrl) || other.initialUrl == initialUrl)&&(identical(other.javascriptEnabled, javascriptEnabled) || other.javascriptEnabled == javascriptEnabled)&&(identical(other.debuggingEnabled, debuggingEnabled) || other.debuggingEnabled == debuggingEnabled)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.initialLoadTimeoutSeconds, initialLoadTimeoutSeconds) || other.initialLoadTimeoutSeconds == initialLoadTimeoutSeconds)&&(identical(other.autoLoadInitialUrl, autoLoadInitialUrl) || other.autoLoadInitialUrl == autoLoadInitialUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,initialUrl,javascriptEnabled,debuggingEnabled,userAgent,initialLoadTimeoutSeconds,autoLoadInitialUrl);

@override
String toString() {
  return 'WebviewConfig(initialUrl: $initialUrl, javascriptEnabled: $javascriptEnabled, debuggingEnabled: $debuggingEnabled, userAgent: $userAgent, initialLoadTimeoutSeconds: $initialLoadTimeoutSeconds, autoLoadInitialUrl: $autoLoadInitialUrl)';
}


}

/// @nodoc
abstract mixin class _$WebviewConfigCopyWith<$Res> implements $WebviewConfigCopyWith<$Res> {
  factory _$WebviewConfigCopyWith(_WebviewConfig value, $Res Function(_WebviewConfig) _then) = __$WebviewConfigCopyWithImpl;
@override @useResult
$Res call({
 String initialUrl, bool javascriptEnabled, bool debuggingEnabled, String userAgent, int initialLoadTimeoutSeconds, bool autoLoadInitialUrl
});




}
/// @nodoc
class __$WebviewConfigCopyWithImpl<$Res>
    implements _$WebviewConfigCopyWith<$Res> {
  __$WebviewConfigCopyWithImpl(this._self, this._then);

  final _WebviewConfig _self;
  final $Res Function(_WebviewConfig) _then;

/// Create a copy of WebviewConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? initialUrl = null,Object? javascriptEnabled = null,Object? debuggingEnabled = null,Object? userAgent = null,Object? initialLoadTimeoutSeconds = null,Object? autoLoadInitialUrl = null,}) {
  return _then(_WebviewConfig(
initialUrl: null == initialUrl ? _self.initialUrl : initialUrl // ignore: cast_nullable_to_non_nullable
as String,javascriptEnabled: null == javascriptEnabled ? _self.javascriptEnabled : javascriptEnabled // ignore: cast_nullable_to_non_nullable
as bool,debuggingEnabled: null == debuggingEnabled ? _self.debuggingEnabled : debuggingEnabled // ignore: cast_nullable_to_non_nullable
as bool,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,initialLoadTimeoutSeconds: null == initialLoadTimeoutSeconds ? _self.initialLoadTimeoutSeconds : initialLoadTimeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,autoLoadInitialUrl: null == autoLoadInitialUrl ? _self.autoLoadInitialUrl : autoLoadInitialUrl // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
