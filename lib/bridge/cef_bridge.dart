import 'dart:ffi';

import 'package:ffi/ffi.dart';

// 네이티브 라이브러리(앱 자체)를 로드
final DynamicLibrary _nativeLib = DynamicLibrary.process();

// C 함수의 시그니처에 맞춰 Dart 타입 정의
typedef _CreateWebviewNative = Void Function(Pointer<Void> view, Pointer<Utf8> url, Int32 width, Int32 height);
typedef _CreateWebviewDart = void Function(Pointer<Void> view, Pointer<Utf8> url, int width, int height);

// Dart에서 호출할 함수 바인딩
final _createWebview =
    _nativeLib.lookup<NativeFunction<_CreateWebviewNative>>('create_webview').asFunction<_CreateWebviewDart>();

/// 네이티브 웹뷰 생성을 요청하는 Dart 래퍼 함수
void callCreateWebview(int viewAddress, String url, int width, int height) {
  final urlC = url.toNativeUtf8();
  _createWebview(Pointer.fromAddress(viewAddress), urlC, width, height);
  malloc.free(urlC);
}
