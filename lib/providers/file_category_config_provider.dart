import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
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

  // ========== 키워드 매핑 관리 메서드 ==========

  /// 키워드 매핑 추가
  Future<void> addKeywordMapping(KeywordMapping mapping) async {
    try {
      state = state.addKeywordMapping(mapping);
      await _saveConfig();
    } catch (e) {
      developer.log('Error adding keyword mapping: $e');
      if (e is KeywordMappingException) {
        rethrow;
      } else {
        throw KeywordMappingException(
          '키워드 매핑 추가 중 오류가 발생했습니다.',
          KeywordMappingErrorType.runtimeRegexError,
          technicalDetails: e.toString(),
          userFriendlyMessage: '키워드 규칙을 추가하는 중 문제가 발생했습니다. 다시 시도해주세요.',
        );
      }
    }
  }

  /// 키워드 매핑 제거
  Future<void> removeKeywordMapping(String pattern) async {
    try {
      state = state.removeKeywordMapping(pattern);
      await _saveConfig();
    } catch (e) {
      developer.log('Error removing keyword mapping: $e');
      if (e is KeywordMappingException) {
        rethrow;
      } else {
        throw KeywordMappingException(
          '키워드 매핑 제거 중 오류가 발생했습니다.',
          KeywordMappingErrorType.runtimeRegexError,
          technicalDetails: e.toString(),
          userFriendlyMessage: '키워드 규칙을 제거하는 중 문제가 발생했습니다. 다시 시도해주세요.',
        );
      }
    }
  }

  /// 키워드 매핑 업데이트
  Future<void> updateKeywordMapping(String oldPattern, KeywordMapping newMapping) async {
    try {
      state = state.updateKeywordMapping(oldPattern, newMapping);
      await _saveConfig();
    } catch (e) {
      developer.log('Error updating keyword mapping: $e');
      if (e is KeywordMappingException) {
        rethrow;
      } else {
        throw KeywordMappingException(
          '키워드 매핑 업데이트 중 오류가 발생했습니다.',
          KeywordMappingErrorType.runtimeRegexError,
          technicalDetails: e.toString(),
          userFriendlyMessage: '키워드 규칙을 수정하는 중 문제가 발생했습니다. 다시 시도해주세요.',
        );
      }
    }
  }

  /// 키워드 매핑 우선순위 업데이트 (여러 매핑의 우선순위를 한 번에 변경)
  Future<void> updateKeywordMappingPriorities(List<KeywordMapping> updatedMappings) async {
    try {
      // 기존 매핑들을 새로운 우선순위로 업데이트
      final updatedKeywordMappings = <KeywordMapping>[];

      for (final updatedMapping in updatedMappings) {
        final existingIndex = state.keywordMappings.indexWhere(
          (existing) => existing.pattern == updatedMapping.pattern,
        );

        if (existingIndex != -1) {
          updatedKeywordMappings.add(updatedMapping);
        }
      }

      // 업데이트되지 않은 매핑들도 포함
      for (final existing in state.keywordMappings) {
        if (!updatedMappings.any((updated) => updated.pattern == existing.pattern)) {
          updatedKeywordMappings.add(existing);
        }
      }

      state = state.copyWith(keywordMappings: updatedKeywordMappings);
      await _saveConfig();
    } catch (e) {
      developer.log('Error updating keyword mapping priorities: $e');
      rethrow;
    }
  }

  /// 키워드 매핑 존재 여부 확인
  bool hasKeywordMapping(String pattern) {
    return state.hasKeywordMapping(pattern);
  }

  /// 특정 패턴의 키워드 매핑 반환
  KeywordMapping? getKeywordMapping(String pattern) {
    return state.getKeywordMapping(pattern);
  }

  /// 우선순위별로 정렬된 키워드 매핑 반환
  List<KeywordMapping> getKeywordMappingsSortedByPriority() {
    return state.getKeywordMappingsSortedByPriority();
  }

  /// 키워드 패턴 유효성 검사 (향상된 버전)
  KeywordMappingException? validateKeywordPattern(String pattern, {bool isRegex = false, bool caseSensitive = false}) {
    final tempMapping = KeywordMapping(
      pattern: pattern,
      category: 'temp', // 임시 카테고리
      isRegex: isRegex,
      caseSensitive: caseSensitive,
    );

    return tempMapping.validatePattern();
  }

  /// 키워드 패턴 유효성 검사 (문자열 반환)
  String? validateKeywordPatternAsString(String pattern, {bool isRegex = false, bool caseSensitive = false}) {
    final error = validateKeywordPattern(pattern, isRegex: isRegex, caseSensitive: caseSensitive);
    return error?.displayMessage;
  }

  /// 키워드 매핑 전체 유효성 검사
  List<KeywordMappingException> validateAllKeywordMappings() {
    return state.validateKeywordMappings();
  }

  /// 키워드 매핑 전체 유효성 검사 (문자열 반환)
  List<String> validateAllKeywordMappingsAsStrings() {
    return state.validateKeywordMappingsAsStrings();
  }

  /// 키워드 매핑 건강성 검사
  ///
  /// 모든 키워드 매핑의 유효성을 검사하고 문제가 있는 규칙들을 반환합니다.
  ///
  /// Returns: 문제가 있는 패턴과 오류 메시지의 맵
  Map<String, String> checkKeywordMappingHealth() {
    final issues = <String, String>{};

    for (final mapping in state.keywordMappings) {
      final validationErrors = mapping.validate();
      if (validationErrors.isNotEmpty) {
        issues[mapping.pattern] = validationErrors.first.displayMessage;
      }
    }

    return issues;
  }

  /// 손상된 키워드 매핑 자동 복구
  ///
  /// 유효하지 않은 키워드 매핑들을 자동으로 제거하거나 수정합니다.
  ///
  /// Returns: 복구된 매핑 개수
  Future<int> repairKeywordMappings() async {
    final validMappings = <KeywordMapping>[];
    int repairedCount = 0;

    for (final mapping in state.keywordMappings) {
      final validationErrors = mapping.validate();

      if (validationErrors.isEmpty) {
        validMappings.add(mapping);
      } else {
        // 복구 시도
        KeywordMapping? repairedMapping;

        try {
          // 패턴이 너무 긴 경우 자르기
          if (validationErrors.any((e) => e.type == KeywordMappingErrorType.patternTooLong)) {
            repairedMapping = mapping.copyWith(pattern: mapping.pattern.substring(0, 200));
          }

          // 카테고리가 너무 긴 경우 자르기
          if (validationErrors.any((e) => e.type == KeywordMappingErrorType.categoryTooLong)) {
            repairedMapping = (repairedMapping ?? mapping).copyWith(category: mapping.category.substring(0, 50));
          }

          // 정규식 오류인 경우 단순 텍스트로 변경
          if (validationErrors.any((e) => e.type == KeywordMappingErrorType.invalidRegex)) {
            repairedMapping = (repairedMapping ?? mapping).copyWith(isRegex: false);
          }

          // 복구된 매핑이 유효한지 확인
          if (repairedMapping != null && repairedMapping.validate().isEmpty) {
            validMappings.add(repairedMapping);
            repairedCount++;
            developer.log('Repaired keyword mapping: ${mapping.pattern} -> ${repairedMapping.pattern}');
          } else {
            developer.log('Could not repair keyword mapping: ${mapping.pattern}');
          }
        } catch (e) {
          developer.log('Error repairing keyword mapping ${mapping.pattern}: $e');
        }
      }
    }

    if (repairedCount > 0) {
      state = state.copyWith(keywordMappings: validMappings);
      await _saveConfig();
    }

    return repairedCount;
  }

  /// 중복 패턴 검사
  bool isDuplicatePattern(String pattern, {String? excludePattern}) {
    return state.keywordMappings.any((mapping) => mapping.pattern == pattern && mapping.pattern != excludePattern);
  }

  /// 키워드 매핑 테스트 (파일명이 패턴과 매치되는지 확인)
  bool testKeywordPattern(String fileName, KeywordMapping mapping) {
    return mapping.safeTestPattern(fileName);
  }

  /// 키워드 매핑 테스트 (상세 결과 반환)
  Map<String, dynamic> testKeywordPatternDetailed(String fileName, KeywordMapping mapping) {
    final result = <String, dynamic>{'matches': false, 'error': null, 'errorType': null, 'suggestion': null};

    try {
      result['matches'] = mapping.testPattern(fileName, throwOnError: true);
    } catch (e) {
      if (e is KeywordMappingException) {
        result['error'] = e.displayMessage;
        result['errorType'] = e.type.toString();
        result['suggestion'] = e.suggestionMessage;
      } else {
        result['error'] = e.toString();
        result['errorType'] = 'unknown';
        result['suggestion'] = '패턴을 확인하고 다시 시도해주세요.';
      }
    }

    return result;
  }

  /// 파일명에 대해 매칭되는 키워드 매핑 찾기
  KeywordMapping? findMatchingKeywordMapping(String fileName) {
    final sortedMappings = getKeywordMappingsSortedByPriority();

    for (final mapping in sortedMappings) {
      if (testKeywordPattern(fileName, mapping)) {
        return mapping;
      }
    }

    return null;
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

/// 우선순위별로 정렬된 키워드 매핑 리스트 provider
final sortedKeywordMappingsProvider = Provider<List<KeywordMapping>>((ref) {
  final notifier = ref.watch(fileCategoryConfigProvider.notifier);
  ref.watch(fileCategoryConfigProvider); // 상태 변경 감지
  return notifier.getKeywordMappingsSortedByPriority();
});

/// 키워드 매핑 리스트 provider (정렬되지 않은 원본)
final keywordMappingsProvider = Provider<List<KeywordMapping>>((ref) {
  final config = ref.watch(fileCategoryConfigProvider);
  return config.keywordMappings;
});

/// 키워드 매핑 개수 provider
final keywordMappingsCountProvider = Provider<int>((ref) {
  final mappings = ref.watch(keywordMappingsProvider);
  return mappings.length;
});

/// 사용자 정의 키워드 매핑만 필터링하는 provider
final customKeywordMappingsProvider = Provider<List<KeywordMapping>>((ref) {
  final mappings = ref.watch(sortedKeywordMappingsProvider);
  return mappings.where((mapping) => mapping.isCustom).toList();
});

/// 정규식 키워드 매핑만 필터링하는 provider
final regexKeywordMappingsProvider = Provider<List<KeywordMapping>>((ref) {
  final mappings = ref.watch(sortedKeywordMappingsProvider);
  return mappings.where((mapping) => mapping.isRegex).toList();
});

/// 단순 텍스트 키워드 매핑만 필터링하는 provider
final textKeywordMappingsProvider = Provider<List<KeywordMapping>>((ref) {
  final mappings = ref.watch(sortedKeywordMappingsProvider);
  return mappings.where((mapping) => !mapping.isRegex).toList();
});
