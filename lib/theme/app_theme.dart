import 'package:flutter/material.dart';

/// 앱 테마 정의
class AppTheme {
  /// 라이트 테마
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.grey.shade700,
      secondary: Colors.grey.shade500,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.white, elevation: 0),
    dividerColor: Colors.grey.shade400,
    cardColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.grey.shade700),
    listTileTheme: ListTileThemeData(selectedTileColor: Colors.blue.withValues(alpha: .1)),
  );

  /// 다크 테마
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue.shade500,
      secondary: Colors.blue.shade300,
      surface: Colors.grey.shade900,
    ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    appBarTheme: AppBarTheme(backgroundColor: Colors.grey.shade900, foregroundColor: Colors.white, elevation: 0),
    dividerColor: Colors.grey.shade800,
    cardColor: Colors.grey.shade800,
    iconTheme: IconThemeData(color: Colors.grey.shade300),
    listTileTheme: ListTileThemeData(selectedTileColor: Colors.blue.withValues(alpha: .2)),
  );
}
