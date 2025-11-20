import 'keyword_mapping.dart';

/// 파일 카테고리 설정을 관리하는 모델
class FileCategoryConfig {
  final Map<String, String> extensionCategories;
  final List<KeywordMapping> keywordMappings;

  const FileCategoryConfig({this.extensionCategories = const {}, this.keywordMappings = const []});

  /// 기본 설정을 반환
  factory FileCategoryConfig.defaultConfig() {
    return const FileCategoryConfig(
      extensionCategories: {
        // 문서
        'pdf': '문서',
        'doc': '문서',
        'docx': '문서',
        'txt': '문서',
        'rtf': '문서',
        'odt': '문서',
        'pages': '문서',
        'xls': '문서',
        'xlsx': '문서',
        'csv': '문서',
        'numbers': '문서',

        // 프레젠테이션
        'ppt': '프레젠테이션',
        'pptx': '프레젠테이션',
        'key': '프레젠테이션',

        // 이미지
        'jpg': '이미지',
        'jpeg': '이미지',
        'png': '이미지',
        'gif': '이미지',
        'bmp': '이미지',
        'tiff': '이미지',
        'svg': '이미지',
        'webp': '이미지',
        'heic': '이미지',

        // 동영상
        'mp4': '동영상',
        'avi': '동영상',
        'mov': '동영상',
        'wmv': '동영상',
        'flv': '동영상',
        'mkv': '동영상',
        'webm': '동영상',
        'm4v': '동영상',

        // 음악
        'mp3': '음악',
        'wav': '음악',
        'flac': '음악',
        'aac': '음악',
        'm4a': '음악',
        'ogg': '음악',
        'wma': '음악',

        // 소스코드
        'dart': '소스코드',
        'js': '소스코드',
        'ts': '소스코드',
        'py': '소스코드',
        'java': '소스코드',
        'cpp': '소스코드',
        'c': '소스코드',
        'h': '소스코드',
        'swift': '소스코드',
        'kt': '소스코드',
        'go': '소스코드',
        'rs': '소스코드',
        'php': '소스코드',
        'rb': '소스코드',
        'html': '소스코드',
        'css': '소스코드',
        'scss': '소스코드',
        'json': '소스코드',
        'xml': '소스코드',
        'yaml': '소스코드',
        'yml': '소스코드',

        // 압축파일
        'zip': '압축파일',
        'rar': '압축파일',
        '7z': '압축파일',
        'tar': '압축파일',
        'gz': '압축파일',
        'bz2': '압축파일',

        // 실행파일
        'exe': '실행파일',
        'app': '실행파일',
        'dmg': '실행파일',
        'pkg': '실행파일',
        'deb': '실행파일',
        'rpm': '실행파일',
      },
    );
  }

  /// copyWith 메서드
  FileCategoryConfig copyWith({Map<String, String>? extensionCategories, List<KeywordMapping>? keywordMappings}) {
    return FileCategoryConfig(
      extensionCategories: extensionCategories ?? this.extensionCategories,
      keywordMappings: keywordMappings ?? this.keywordMappings,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'extensionCategories': extensionCategories,
      'keywordMappings': keywordMappings.map((mapping) => mapping.toJson()).toList(),
    };
  }

  /// JSON에서 생성
  factory FileCategoryConfig.fromJson(Map<String, dynamic> json) {
    return FileCategoryConfig(
      extensionCategories: Map<String, String>.from(json['extensionCategories'] ?? {}),
      keywordMappings:
          (json['keywordMappings'] as List<dynamic>?)
              ?.map((item) => KeywordMapping.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileCategoryConfig &&
        _mapEquals(extensionCategories, other.extensionCategories) &&
        _listEquals(keywordMappings, other.keywordMappings);
  }

  @override
  int get hashCode => extensionCategories.hashCode ^ keywordMappings.hashCode;

  /// 키워드 매핑 추가
  FileCategoryConfig addKeywordMapping(KeywordMapping mapping) {
    // 유효성 검사
    final validationErrors = mapping.validate();
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    // 중복 패턴 검사
    if (keywordMappings.any((existing) => existing.pattern == mapping.pattern)) {
      throw const KeywordMappingException(
        '동일한 패턴이 이미 존재합니다.',
        KeywordMappingErrorType.duplicatePattern,
        userFriendlyMessage: '이미 같은 패턴의 규칙이 있습니다. 다른 패턴을 사용하거나 기존 규칙을 수정해주세요.',
      );
    }

    final updatedMappings = List<KeywordMapping>.from(keywordMappings)..add(mapping);
    return copyWith(keywordMappings: updatedMappings);
  }

  /// 키워드 매핑 제거
  FileCategoryConfig removeKeywordMapping(String pattern) {
    final updatedMappings = keywordMappings.where((mapping) => mapping.pattern != pattern).toList();
    return copyWith(keywordMappings: updatedMappings);
  }

  /// 키워드 매핑 업데이트
  FileCategoryConfig updateKeywordMapping(String oldPattern, KeywordMapping newMapping) {
    // 유효성 검사
    final validationErrors = newMapping.validate();
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    // 패턴이 변경된 경우 중복 검사
    if (oldPattern != newMapping.pattern && keywordMappings.any((existing) => existing.pattern == newMapping.pattern)) {
      throw const KeywordMappingException(
        '동일한 패턴이 이미 존재합니다.',
        KeywordMappingErrorType.duplicatePattern,
        userFriendlyMessage: '이미 같은 패턴의 규칙이 있습니다. 다른 패턴을 사용해주세요.',
      );
    }

    final updatedMappings =
        keywordMappings.map((mapping) => mapping.pattern == oldPattern ? newMapping : mapping).toList();
    return copyWith(keywordMappings: updatedMappings);
  }

  /// 우선순위별로 정렬된 키워드 매핑 반환
  List<KeywordMapping> getKeywordMappingsSortedByPriority() {
    final sortedMappings = List<KeywordMapping>.from(keywordMappings);
    sortedMappings.sort((a, b) => a.priority.compareTo(b.priority));
    return sortedMappings;
  }

  /// 키워드 매핑 존재 여부 확인
  bool hasKeywordMapping(String pattern) {
    return keywordMappings.any((mapping) => mapping.pattern == pattern);
  }

  /// 특정 패턴의 키워드 매핑 반환
  KeywordMapping? getKeywordMapping(String pattern) {
    try {
      return keywordMappings.firstWhere((mapping) => mapping.pattern == pattern);
    } catch (e) {
      return null;
    }
  }

  /// 키워드 매핑 유효성 검사
  List<KeywordMappingException> validateKeywordMappings() {
    final errors = <KeywordMappingException>[];
    final patterns = <String>{};

    for (final mapping in keywordMappings) {
      // 개별 매핑 유효성 검사
      final mappingErrors = mapping.validate();
      errors.addAll(mappingErrors);

      // 중복 패턴 검사
      if (patterns.contains(mapping.pattern)) {
        errors.add(
          KeywordMappingException(
            '중복된 패턴이 있습니다: ${mapping.pattern}',
            KeywordMappingErrorType.duplicatePattern,
            userFriendlyMessage: '패턴 "${mapping.pattern}"이 중복됩니다. 중복된 규칙을 제거해주세요.',
          ),
        );
      } else {
        patterns.add(mapping.pattern);
      }
    }

    return errors;
  }

  /// 키워드 매핑 일괄 유효성 검사 (문자열 메시지 반환)
  List<String> validateKeywordMappingsAsStrings() {
    return validateKeywordMappings().map((error) => error.displayMessage).toList();
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 개별 확장자 매핑 항목
class ExtensionMapping {
  final String extension;
  final String category;
  final bool isCustom;

  const ExtensionMapping({required this.extension, required this.category, this.isCustom = false});

  /// copyWith 메서드
  ExtensionMapping copyWith({String? extension, String? category, bool? isCustom}) {
    return ExtensionMapping(
      extension: extension ?? this.extension,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'extension': extension, 'category': category, 'isCustom': isCustom};
  }

  /// JSON에서 생성
  factory ExtensionMapping.fromJson(Map<String, dynamic> json) {
    return ExtensionMapping(
      extension: json['extension'] as String,
      category: json['category'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtensionMapping &&
        other.extension == extension &&
        other.category == category &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => extension.hashCode ^ category.hashCode ^ isCustom.hashCode;
}
