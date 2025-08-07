import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 파일 카테고리 설정을 관리하는 StateNotifier
class FileCategoryConfigNotifier extends StateNotifier<FileCategoryConfig> {
  static const String _storageKey = 'file_category_config';
  final SharedPreferences _prefs;

  FileCategoryConfigNotifier(this._prefs) : super(FileCategoryConfig.defaultConfig()) {
    _loadConfig();
  }

  /// 저장된 설정을 로드
  Future<void> _loadConfig() async {
    try {
      final configJson = _prefs.getString(_storageKey);
      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        state = FileCategoryConfig.fromJson(configMap);
      }
    } catch (e) {
      developer.log('Error loading file category config: $e');
      // 오류 발생 시 기본 설정 사용
      state = FileCategoryConfig.defaultConfig();
    }
  }

  /// 설정을 저장
  Future<void> _saveConfig() async {
    try {
      final configJson = jsonEncode(state.toJson());
      await _prefs.setString(_storageKey, configJson);
    } catch (e) {
      developer.log('Error saving file category config: $e');
    }
  }

  /// 확장자 매핑 추가
  Future<void> addExtensionMapping(String extension, String category) async {
    final cleanExtension = extension.toLowerCase().replaceFirst('.', '');
    final updatedExtensions = Map<String, String>.from(state.extensionCategories);
    updatedExtensions[cleanExtension] = category;

    state = state.copyWith(extensionCategories: updatedExtensions);
    await _saveConfig();
  }

  /// 확장자 매핑 제거
  Future<void> removeExtensionMapping(String extension) async {
    final cleanExtension = extension.toLowerCase().replaceFirst('.', '');
    final updatedExtensions = Map<String, String>.from(state.extensionCategories);
    updatedExtensions.remove(cleanExtension);

    state = state.copyWith(extensionCategories: updatedExtensions);
    await _saveConfig();
  }

  /// 확장자 매핑 수정
  Future<void> updateExtensionMapping(String extension, String newCategory) async {
    final cleanExtension = extension.toLowerCase().replaceFirst('.', '');
    if (state.extensionCategories.containsKey(cleanExtension)) {
      final updatedExtensions = Map<String, String>.from(state.extensionCategories);
      updatedExtensions[cleanExtension] = newCategory;

      state = state.copyWith(extensionCategories: updatedExtensions);
      await _saveConfig();
    }
  }

  /// 설정을 기본값으로 리셋
  Future<void> resetToDefault() async {
    state = FileCategoryConfig.defaultConfig();
    await _saveConfig();
  }

  /// 설정을 JSON으로 내보내기
  String exportConfig() {
    return jsonEncode(state.toJson());
  }

  /// JSON에서 설정 가져오기
  Future<bool> importConfig(String configJson) async {
    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      final newConfig = FileCategoryConfig.fromJson(configMap);
      state = newConfig;
      await _saveConfig();
      return true;
    } catch (e) {
      developer.log('Error importing config: $e');
      return false;
    }
  }

  /// 특정 확장자의 카테고리 조회
  String? getCategoryForExtension(String extension) {
    final cleanExtension = extension.toLowerCase().replaceFirst('.', '');
    return state.extensionCategories[cleanExtension];
  }

  /// 모든 확장자 매핑을 ExtensionMapping 리스트로 반환
  List<ExtensionMapping> getExtensionMappings() {
    final defaultConfig = FileCategoryConfig.defaultConfig();
    return state.extensionCategories.entries.map((entry) {
        final isCustom =
            !defaultConfig.extensionCategories.containsKey(entry.key) ||
            defaultConfig.extensionCategories[entry.key] != entry.value;
        return ExtensionMapping(extension: entry.key, category: entry.value, isCustom: isCustom);
      }).toList()
      ..sort((a, b) => a.extension.compareTo(b.extension));
  }

  /// 사용 가능한 카테고리 목록 반환
  List<String> getAvailableCategories() {
    return ['문서', '프레젠테이션', '이미지', '동영상', '음악', '소스코드', '압축파일', '실행파일', '기타'];
  }
}

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden');
});

/// 파일 카테고리 설정 provider
final fileCategoryConfigProvider = StateNotifierProvider<FileCategoryConfigNotifier, FileCategoryConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FileCategoryConfigNotifier(prefs);
});

/// 확장자 매핑 리스트 provider
final extensionMappingsProvider = Provider<List<ExtensionMapping>>((ref) {
  final notifier = ref.watch(fileCategoryConfigProvider.notifier);
  ref.watch(fileCategoryConfigProvider); // 상태 변경 감지
  return notifier.getExtensionMappings();
});

/// 사용 가능한 카테고리 리스트 provider
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final notifier = ref.watch(fileCategoryConfigProvider.notifier);
  return notifier.getAvailableCategories();
});
