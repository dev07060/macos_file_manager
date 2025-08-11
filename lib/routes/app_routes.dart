import 'package:flutter/material.dart';
import 'package:macos_file_manager/home.dart';
import 'package:macos_file_manager/pages/webview_page.dart';

/// Application routes configuration.
class AppRoutes {
  static const String home = '/';
  static const String webview = '/webview';

  /// Route generator for the application.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
      case webview:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const WebviewPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth slide transition for webview
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      default:
        return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
    }
  }

  /// Get all available routes.
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomePage(),
    webview: (context) => const WebviewPage(),
  };
}
