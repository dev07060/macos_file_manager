/// 키워드 기반 파일 분류를 위한 매핑 모델
class KeywordMapping {
  final String pattern;
  final String category;
  final bool isRegex;
  final bool caseSensitive;
  final int priority;
  final bool isCustom;

  const KeywordMapping({
    required this.pattern,
    required this.category,
    this.isRegex = false,
    this.caseSensitive = false,
    this.priority = 0,
    this.isCustom = true,
  });

  /// copyWith 메서드
  KeywordMapping copyWith({
    String? pattern,
    String? category,
    bool? isRegex,
    bool? caseSensitive,
    int? priority,
    bool? isCustom,
  }) {
    return KeywordMapping(
      pattern: pattern ?? this.pattern,
      category: category ?? this.category,
      isRegex: isRegex ?? this.isRegex,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      priority: priority ?? this.priority,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'category': category,
      'isRegex': isRegex,
      'caseSensitive': caseSensitive,
      'priority': priority,
      'isCustom': isCustom,
    };
  }

  /// JSON에서 생성
  factory KeywordMapping.fromJson(Map<String, dynamic> json) {
    return KeywordMapping(
      pattern: json['pattern'] as String,
      category: json['category'] as String,
      isRegex: json['isRegex'] as bool? ?? false,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

  /// 정규식 패턴 유효성 검사
  bool isValidRegexPattern() {
    if (!isRegex) return true; // 정규식이 아니면 항상 유효

    try {
      RegExp(pattern, caseSensitive: caseSensitive);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 패턴 유효성 검사 (빈 패턴 체크 포함)
  String? validatePattern() {
    if (pattern.trim().isEmpty) {
      return '패턴이 비어있습니다.';
    }

    if (isRegex && !isValidRegexPattern()) {
      return '유효하지 않은 정규식 패턴입니다.';
    }

    return null; // 유효함
  }

  /// 카테고리 유효성 검사
  String? validateCategory() {
    if (category.trim().isEmpty) {
      return '카테고리가 비어있습니다.';
    }

    return null; // 유효함
  }

  /// 전체 유효성 검사
  List<String> validate() {
    final errors = <String>[];

    final patternError = validatePattern();
    if (patternError != null) {
      errors.add(patternError);
    }

    final categoryError = validateCategory();
    if (categoryError != null) {
      errors.add(categoryError);
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeywordMapping &&
        other.pattern == pattern &&
        other.category == category &&
        other.isRegex == isRegex &&
        other.caseSensitive == caseSensitive &&
        other.priority == priority &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode {
    return pattern.hashCode ^
        category.hashCode ^
        isRegex.hashCode ^
        caseSensitive.hashCode ^
        priority.hashCode ^
        isCustom.hashCode;
  }

  @override
  String toString() {
    return 'KeywordMapping(pattern: $pattern, category: $category, isRegex: $isRegex, caseSensitive: $caseSensitive, priority: $priority, isCustom: $isCustom)';
  }
}

/// 키워드 매핑 관련 예외 클래스
class KeywordMappingException implements Exception {
  final String message;
  final KeywordMappingErrorType type;

  const KeywordMappingException(this.message, this.type);

  @override
  String toString() => 'KeywordMappingException: $message';
}

/// 키워드 매핑 오류 타입
enum KeywordMappingErrorType { duplicatePattern, emptyPattern, invalidRegex, emptyCategory, invalidPriority }
