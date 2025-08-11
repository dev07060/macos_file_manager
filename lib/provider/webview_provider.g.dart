// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$webviewConfigHash() => r'453416e5253aa0bf095891b4f2020c406e5d37b2';

/// Provider for webview configuration
///
/// Copied from [webviewConfig].
@ProviderFor(webviewConfig)
final webviewConfigProvider = AutoDisposeProvider<WebviewConfig>.internal(
  webviewConfig,
  name: r'webviewConfigProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$webviewConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WebviewConfigRef = AutoDisposeProviderRef<WebviewConfig>;
String _$webviewHash() => r'4a9bc6973038b8cd0f333af1081ab9a7e367642a';

/// Provider for webview state management
///
/// Copied from [Webview].
@ProviderFor(Webview)
final webviewProvider =
    AutoDisposeNotifierProvider<Webview, WebviewState>.internal(
      Webview.new,
      name: r'webviewProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product') ? null : _$webviewHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Webview = AutoDisposeNotifier<WebviewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
