import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CefWebView extends StatelessWidget {
  final String initialUrl;

  const CefWebView({super.key, required this.initialUrl});

  @override
  Widget build(BuildContext context) {
    // AppDelegate에 등록한 ID
    const String viewType = 'com.example/cef_webview';

    // 네이티브 뷰에 전달할 파라미터
    final Map<String, dynamic> creationParams = <String, dynamic>{'initialUrl': initialUrl};

    return AppKitView(
      viewType: viewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
