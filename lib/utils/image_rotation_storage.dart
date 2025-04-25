import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class ImageRotationStorage {
  static const String _prefix = 'image_rotation_';

  static String _getKey(String imagePath) {
    return '$_prefix${imagePath.hashCode}';
  }

  static Future<void> saveRotationState(String imagePath, int angle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(imagePath);
      await prefs.setInt(key, angle);
    } catch (e) {
      log('Failed to save rotation state: $e');
    }
  }

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

  static Future<void> deleteRotationState(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(imagePath);
      await prefs.remove(key);
    } catch (e) {
      log('Failed to delete rotation state: $e');
    }
  }

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
