import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 모드 상태 관리를 위한 프로바이더
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// 테마 모드를 관리하는 Notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadThemePreference();
  }

  /// 저장된 테마 설정 로드
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// 테마 모드 전환
  Future<void> toggleTheme() async {
    final isDarkMode = state == ThemeMode.dark;
    state = isDarkMode ? ThemeMode.light : ThemeMode.dark;

    // 테마 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', !isDarkMode);
  }

  /// 현재 다크 모드 여부 반환
  bool isDarkMode() => state == ThemeMode.dark;
}
