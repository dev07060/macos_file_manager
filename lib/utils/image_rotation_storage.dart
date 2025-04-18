import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class ImageRotationStorage {
  static const String _prefix = 'image_rotation_';

  // 이미지 경로를 키로 변환
  static String _getKey(String imagePath) {
    // 전체 경로 대신 파일명만 사용하면 충돌 가능성이 있으므로
    // 경로의 해시값을 사용하여 고유한 키 생성
    return '$_prefix${imagePath.hashCode}';
  }

  // 회전 상태 저장
  static Future<void> saveRotationState(String imagePath, int angle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(imagePath);
      await prefs.setInt(key, angle);
    } catch (e) {
      log('Failed to save rotation state: $e');
    }
  }

  // 회전 상태 로드
  static Future<int> loadRotationState(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(imagePath);
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      log('Failed to load rotation state: $e');
      return 0;
    }
  }

  // 회전 상태 삭제 (파일 삭제 시 사용)
  static Future<void> deleteRotationState(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(imagePath);
      await prefs.remove(key);
    } catch (e) {
      log('Failed to delete rotation state: $e');
    }
  }

  // 모든 회전 상태 삭제
  static Future<void> clearAllRotationStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      log('Failed to clear rotation states: $e');
    }
  }
}
