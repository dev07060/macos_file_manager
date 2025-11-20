import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';
import 'package:path/path.dart' as path;

// 정리 방식 열거형
enum OrganizationMethod {
  category, // 카테고리별 정리
  date, // 날짜별 정리
  fileType, // 파일 타입별 정리
  size, // 크기별 정리
  project, // 프로젝트별 정리
  custom, // 사용자 정의 정리
}

// 정리 방식 정보 클래스
class OrganizationMethodInfo {
  final OrganizationMethod method;
  final String displayName;
  final String description;
  final String icon;

  const OrganizationMethodInfo({
    required this.method,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}

class FileOrganizationService {
  final Ref _ref;

  FileOrganizationService(this._ref);

  // 정리 방식 목록
  static const List<OrganizationMethodInfo> organizationMethods = [
    OrganizationMethodInfo(
      method: OrganizationMethod.category,
      displayName: '카테고리별 정리',
      description: '파일 내용을 분석하여 카테고리별로 정리합니다',
      icon: '📁',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.date,
      displayName: '날짜별 정리',
      description: '파일 생성 날짜나 수정 날짜를 기준으로 정리합니다',
      icon: '📅',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.fileType,
      displayName: '파일 타입별 정리',
      description: '파일 확장자를 기준으로 정리합니다',
      icon: '📄',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.size,
      displayName: '크기별 정리',
      description: '파일 크기를 기준으로 정리합니다',
      icon: '📏',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.project,
      displayName: '프로젝트별 정리',
      description: '파일 내용을 분석하여 프로젝트별로 정리합니다',
      icon: '🚀',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.custom,
      displayName: '사용자 정의 정리',
      description: '사용자가 정의한 규칙에 따라 정리합니다',
      icon: '⚙️',
    ),
  ];

  /// 현재 설정된 카테고리 구성을 가져옵니다
  FileCategoryConfig get _config => _ref.read(fileCategoryConfigProvider);

  // 기존 메서드 - 카테고리별 분류
  String classifyFile(String fileName, String contentSnippet) {
    return _categorizeByContent(fileName, contentSnippet);
  }

  /// 상세한 파일 분류 결과 반환 (키워드 매칭 정보 포함)
  FileOrganizationResult classifyFileWithDetails(String filePath, String fileName, String contentSnippet) {
    // 키워드 기반 분류 시도 (최우선)
    final keywordMappings = _config.getKeywordMappingsSortedByPriority();
    final keywordResult = _categorizeByKeywordWithDetails(fileName, keywordMappings);

    if (keywordResult != null) {
      return FileOrganizationResult.keyword(
        filePath: filePath,
        fileName: fileName,
        category: keywordResult['category']!,
        matchedPattern: keywordResult['pattern']!,
      );
    }

    // 확장자 기반 분류
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    if (_config.extensionCategories.containsKey(extension)) {
      return FileOrganizationResult.extension(
        filePath: filePath,
        fileName: fileName,
        category: _config.extensionCategories[extension]!,
        matchedExtension: extension,
      );
    }

    // 내용 기반 추가 분류 (기타)
    final category = _categorizeByContentOnly(contentSnippet);
    return FileOrganizationResult.other(filePath: filePath, fileName: fileName, category: category);
  }

  // 새로운 메서드 - 다양한 정리 방식 지원
  String organizeFile(
    String fileName,
    String contentSnippet,
    OrganizationMethod method, {
    String? customRule,
    Map<String, dynamic>? fileMetadata,
    FileCategoryConfig? config,
  }) {
    switch (method) {
      case OrganizationMethod.category:
        return _categorizeByContent(fileName, contentSnippet);
      case OrganizationMethod.date:
        return _categorizeByDate(fileName, fileMetadata);
      case OrganizationMethod.fileType:
        return _categorizeByFileType(fileName);
      case OrganizationMethod.size:
        return _categorizeBySize(fileMetadata);
      case OrganizationMethod.project:
        return _categorizeByProject(fileName, contentSnippet);
      case OrganizationMethod.custom:
        return _categorizeByCustomRule(fileName, contentSnippet, customRule);
    }
  }

  /// 키워드 기반 파일 분류 (외부 호출용)
  ///
  /// 특정 설정을 사용하여 파일을 키워드 기반으로 분류합니다.
  ///
  /// [fileName] 검사할 파일명
  /// [contentSnippet] 파일 내용 (현재는 사용하지 않음)
  /// [config] 사용할 파일 카테고리 설정 (null인 경우 현재 설정 사용)
  ///
  /// Returns: 매칭되는 카테고리명 또는 '기타' (매칭되는 규칙이 없는 경우)
  String organizeFileByKeyword(String fileName, String contentSnippet, [FileCategoryConfig? config]) {
    final targetConfig = config ?? _config;
    final keywordCategory = _categorizeByKeyword(fileName, targetConfig.getKeywordMappingsSortedByPriority());
    return keywordCategory ?? AppStrings.other;
  }

  // 카테고리별 분류 로직
  String _categorizeByContent(String fileName, String contentSnippet) {
    final lowerContent = contentSnippet.toLowerCase();

    // 키워드 기반 분류 (최우선)
    final keywordCategory = _categorizeByKeyword(fileName, _config.getKeywordMappingsSortedByPriority());
    if (keywordCategory != null) {
      return keywordCategory;
    }

    // 확장자 기반 분류
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    if (_config.extensionCategories.containsKey(extension)) {
      return _config.extensionCategories[extension]!;
    }

    // 내용 기반 추가 분류
    if (lowerContent.contains('import') && lowerContent.contains('class')) {
      return AppStrings.sourceCode;
    }
    if (lowerContent.contains('invoice') || lowerContent.contains('bill')) {
      return AppStrings.invoice;
    }
    if (lowerContent.contains('contract') || lowerContent.contains('agreement')) {
      return AppStrings.contract;
    }

    return AppStrings.other;
  }

  /// 키워드 기반 파일 분류
  ///
  /// 파일명을 키워드 매핑 규칙과 비교하여 해당하는 카테고리를 반환합니다.
  /// 우선순위가 높은 규칙부터 순서대로 검사하며, 첫 번째로 매칭되는 규칙의 카테고리를 반환합니다.
  /// 런타임 오류 발생 시 자동으로 복구하여 다음 규칙을 시도합니다.
  ///
  /// [fileName] 검사할 파일명
  /// [keywordMappings] 우선순위별로 정렬된 키워드 매핑 리스트
  ///
  /// Returns: 매칭되는 카테고리명 또는 null (매칭되는 규칙이 없는 경우)
  String? _categorizeByKeyword(String fileName, List<KeywordMapping> keywordMappings) {
    if (keywordMappings.isEmpty) {
      return null;
    }

    final failedPatterns = <String>[];

    for (final mapping in keywordMappings) {
      try {
        // 안전한 패턴 매칭 사용 (오류 복구 포함)
        if (mapping.safeTestPattern(fileName)) {
          return mapping.category;
        }
      } catch (e) {
        // 런타임 오류 발생 시 로그 기록하고 다음 매핑으로 진행
        failedPatterns.add(mapping.pattern);
        debugPrint('Runtime error for pattern "${mapping.pattern}": $e');

        // 오류 복구 시도: 정규식을 단순 텍스트로 처리
        if (mapping.isRegex) {
          try {
            final searchText = mapping.caseSensitive ? fileName : fileName.toLowerCase();
            final pattern = mapping.caseSensitive ? mapping.pattern : mapping.pattern.toLowerCase();

            if (searchText.contains(pattern)) {
              debugPrint('Fallback text matching succeeded for pattern "${mapping.pattern}"');
              return mapping.category;
            }
          } catch (fallbackError) {
            debugPrint('Fallback matching also failed for pattern "${mapping.pattern}": $fallbackError');
          }
        }

        continue;
      }
    }

    // 실패한 패턴들이 있으면 로그에 기록
    if (failedPatterns.isNotEmpty) {
      debugPrint('Failed to match patterns for file "$fileName": ${failedPatterns.join(", ")}');
    }

    return null; // 매칭되는 패턴 없음
  }

  /// 키워드 기반 파일 분류 (상세 정보 포함)
  ///
  /// 파일명을 키워드 매핑 규칙과 비교하여 매칭되는 카테고리와 패턴 정보를 반환합니다.
  ///
  /// [fileName] 검사할 파일명
  /// [keywordMappings] 우선순위별로 정렬된 키워드 매핑 리스트
  ///
  /// Returns: 매칭 정보 맵 (category, pattern) 또는 null
  Map<String, String>? _categorizeByKeywordWithDetails(String fileName, List<KeywordMapping> keywordMappings) {
    if (keywordMappings.isEmpty) {
      return null;
    }

    final failedPatterns = <String>[];

    for (final mapping in keywordMappings) {
      try {
        // 안전한 패턴 매칭 사용 (오류 복구 포함)
        if (mapping.safeTestPattern(fileName)) {
          debugPrint('File "$fileName" matched keyword pattern "${mapping.pattern}" -> category "${mapping.category}"');
          return {'category': mapping.category, 'pattern': mapping.pattern};
        }
      } catch (e) {
        // 런타임 오류 발생 시 로그 기록하고 다음 매핑으로 진행
        failedPatterns.add(mapping.pattern);
        debugPrint('Runtime error for pattern "${mapping.pattern}": $e');

        // 오류 복구 시도: 정규식을 단순 텍스트로 처리
        if (mapping.isRegex) {
          try {
            final searchText = mapping.caseSensitive ? fileName : fileName.toLowerCase();
            final pattern = mapping.caseSensitive ? mapping.pattern : mapping.pattern.toLowerCase();

            if (searchText.contains(pattern)) {
              debugPrint('Fallback text matching succeeded for pattern "${mapping.pattern}"');
              debugPrint(
                'File "$fileName" matched keyword pattern "${mapping.pattern}" (fallback) -> category "${mapping.category}"',
              );
              return {'category': mapping.category, 'pattern': mapping.pattern};
            }
          } catch (fallbackError) {
            debugPrint('Fallback matching also failed for pattern "${mapping.pattern}": $fallbackError');
          }
        }

        continue;
      }
    }

    // 실패한 패턴들이 있으면 로그에 기록
    if (failedPatterns.isNotEmpty) {
      debugPrint('Failed to match patterns for file "$fileName": ${failedPatterns.join(", ")}');
    }

    return null; // 매칭되는 패턴 없음
  }

  /// 내용 기반 분류 (키워드/확장자 제외)
  String _categorizeByContentOnly(String contentSnippet) {
    final lowerContent = contentSnippet.toLowerCase();

    // 내용 기반 추가 분류
    if (lowerContent.contains('import') && lowerContent.contains('class')) {
      return AppStrings.sourceCode;
    }
    if (lowerContent.contains('invoice') || lowerContent.contains('bill')) {
      return AppStrings.invoice;
    }
    if (lowerContent.contains('contract') || lowerContent.contains('agreement')) {
      return AppStrings.contract;
    }

    return AppStrings.other;
  }

  /// 키워드 매핑 규칙의 건강성 검사
  ///
  /// 모든 키워드 매핑 규칙을 검사하여 문제가 있는 규칙들을 식별합니다.
  ///
  /// Returns: 문제가 있는 규칙들의 패턴과 오류 메시지 맵
  Map<String, String> validateKeywordMappings(List<KeywordMapping> keywordMappings) {
    final issues = <String, String>{};

    for (final mapping in keywordMappings) {
      final validationErrors = mapping.validate();
      if (validationErrors.isNotEmpty) {
        issues[mapping.pattern] = validationErrors.first.displayMessage;
      }

      // 런타임 테스트 수행
      try {
        mapping.testPattern('test_file.txt', throwOnError: true);
      } catch (e) {
        if (e is KeywordMappingException) {
          issues[mapping.pattern] = e.displayMessage;
        } else {
          issues[mapping.pattern] = '런타임 오류: ${e.toString()}';
        }
      }
    }

    return issues;
  }

  /// 안전한 키워드 기반 파일 분류 (오류 복구 포함)
  ///
  /// 오류가 발생한 규칙들을 자동으로 건너뛰고 작동하는 규칙만 사용합니다.
  ///
  /// [fileName] 검사할 파일명
  /// [keywordMappings] 키워드 매핑 리스트
  ///
  /// Returns: 매칭 결과와 오류 정보를 포함한 맵
  Map<String, dynamic> safeCategorizeByKeyword(String fileName, List<KeywordMapping> keywordMappings) {
    final result = <String, dynamic>{
      'category': null,
      'matchedPattern': null,
      'errors': <String>[],
      'skippedPatterns': <String>[],
    };

    if (keywordMappings.isEmpty) {
      return result;
    }

    for (final mapping in keywordMappings) {
      try {
        if (mapping.safeTestPattern(fileName)) {
          result['category'] = mapping.category;
          result['matchedPattern'] = mapping.pattern;
          return result;
        }
      } catch (e) {
        final errorMessage = 'Pattern "${mapping.pattern}": ${e.toString()}';
        (result['errors'] as List<String>).add(errorMessage);
        (result['skippedPatterns'] as List<String>).add(mapping.pattern);
        continue;
      }
    }

    return result;
  }

  // 날짜별 분류 로직
  String _categorizeByDate(String fileName, Map<String, dynamic>? metadata) {
    final fileDate = metadata?['creationDate'] ?? metadata?['modificationDate'] ?? DateTime.now();
    final dateTime = fileDate is DateTime ? fileDate : DateTime.tryParse(fileDate.toString()) ?? DateTime.now();

    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    if (difference <= 7) {
      return '최근 1주일';
    } else if (difference <= 30) {
      return '최근 1개월';
    } else if (difference <= 90) {
      return '최근 3개월';
    } else if (dateTime.year == now.year) {
      return '${dateTime.year}년 ${dateTime.month}월';
    } else {
      return '${dateTime.year}년';
    }
  }

  // 파일 타입별 분류 로직
  String _categorizeByFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');

    if (_config.extensionCategories.containsKey(extension)) {
      return _config.extensionCategories[extension]!;
    }

    // 확장자가 없는 경우 파일명으로 추정
    if (extension.isEmpty) {
      final lowerFileName = fileName.toLowerCase();
      if (lowerFileName.contains('readme') || lowerFileName.contains('license')) {
        return AppStrings.document;
      }
      if (lowerFileName.contains('makefile') || lowerFileName.contains('dockerfile')) {
        return AppStrings.sourceCode;
      }
    }

    return AppStrings.other;
  }

  // 크기별 분류 로직
  String _categorizeBySize(Map<String, dynamic>? metadata) {
    final fileSize = metadata?['size'] ?? 0;
    final sizeInBytes = fileSize as num;

    if (sizeInBytes < 1024 * 1024) {
      // 1MB 미만
      return '소용량 (1MB 미만)';
    } else if (sizeInBytes < 10 * 1024 * 1024) {
      // 10MB 미만
      return '중용량 (1MB-10MB)';
    } else if (sizeInBytes < 100 * 1024 * 1024) {
      // 100MB 미만
      return '대용량 (10MB-100MB)';
    } else {
      return '초대용량 (100MB 이상)';
    }
  }

  // 프로젝트별 분류 로직
  String _categorizeByProject(String fileName, String contentSnippet) {
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = contentSnippet.toLowerCase();

    // Flutter/Dart 프로젝트
    if (lowerFileName.contains('.dart') || lowerContent.contains('flutter') || lowerContent.contains('dart')) {
      return 'Flutter 앱 개발';
    }

    // 웹 개발
    if (lowerFileName.contains('.html') ||
        lowerFileName.contains('.css') ||
        lowerFileName.contains('.js') ||
        lowerContent.contains('html') ||
        lowerContent.contains('css') ||
        lowerContent.contains('javascript')) {
      return '웹사이트 개발';
    }

    // 디자인 파일
    if (lowerFileName.contains('design') ||
        lowerFileName.contains('ui') ||
        lowerFileName.contains('mockup') ||
        lowerContent.contains('design') ||
        lowerContent.contains('mockup')) {
      return '디자인 프로젝트';
    }

    // 재무 관련
    if (lowerFileName.contains('finance') ||
        lowerFileName.contains('budget') ||
        lowerFileName.contains('invoice') ||
        lowerContent.contains('finance') ||
        lowerContent.contains('budget')) {
      return '재무 관리';
    }

    // 마케팅 관련
    if (lowerFileName.contains('marketing') ||
        lowerFileName.contains('campaign') ||
        lowerFileName.contains('ad') ||
        lowerContent.contains('marketing') ||
        lowerContent.contains('campaign')) {
      return '마케팅 자료';
    }

    // 개인 사진/동영상
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'].contains(extension)) {
      if (lowerFileName.contains('photo') || lowerFileName.contains('pic') || lowerFileName.contains('img')) {
        return '개인 사진';
      }
      if (lowerFileName.contains('video') || lowerFileName.contains('movie')) {
        return '개인 동영상';
      }
    }

    return '일반 프로젝트';
  }

  // 사용자 정의 규칙 분류 로직
  String _categorizeByCustomRule(String fileName, String contentSnippet, String? customRule) {
    if (customRule == null || customRule.isEmpty) {
      return _categorizeByContent(fileName, contentSnippet);
    }

    // 간단한 키워드 기반 규칙 처리
    final rules = customRule.split(',').map((e) => e.trim()).toList();
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = contentSnippet.toLowerCase();

    for (final rule in rules) {
      if (rule.contains(':')) {
        final parts = rule.split(':');
        if (parts.length == 2) {
          final keyword = parts[0].trim().toLowerCase();
          final category = parts[1].trim();

          if (lowerFileName.contains(keyword) || lowerContent.contains(keyword)) {
            return category;
          }
        }
      }
    }

    return '사용자 정의';
  }
}

final fileOrganizationServiceProvider = Provider<FileOrganizationService>((ref) {
  return FileOrganizationService(ref);
});
