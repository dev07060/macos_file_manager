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
      final regex = RegExp(pattern, caseSensitive: caseSensitive);
      // 추가 검증: 빈 문자열과 매칭되는지 확인 (무한 루프 방지)
      if (regex.hasMatch('')) {
        // 빈 문자열과 매칭되는 패턴은 위험할 수 있음
        return pattern.isNotEmpty; // 패턴이 비어있지 않으면 허용
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 정규식 패턴의 복잡도 검사
  bool isPatternTooComplex() {
    if (!isRegex) return false;

    // 복잡한 패턴 특성들 검사
    final complexPatterns = [
      r'(?=.*(?=.*(?=.*', // 중첩된 lookahead
      r'(?<=.*(?<=.*(?<=.*', // 중첩된 lookbehind
      r'(.{100,})', // 매우 긴 반복
      r'(\w+\s*){50,}', // 많은 반복
    ];

    for (final complexPattern in complexPatterns) {
      if (pattern.contains(complexPattern)) {
        return true;
      }
    }

    // 패턴 길이 검사
    return pattern.length > 200;
  }

  /// 패턴 유효성 검사 (빈 패턴 체크 포함)
  KeywordMappingException? validatePattern() {
    final trimmedPattern = pattern.trim();

    if (trimmedPattern.isEmpty) {
      return const KeywordMappingException(
        '패턴이 비어있습니다.',
        KeywordMappingErrorType.emptyPattern,
        userFriendlyMessage: '패턴을 입력해주세요.',
      );
    }

    if (trimmedPattern.length > 200) {
      return const KeywordMappingException(
        '패턴이 너무 깁니다.',
        KeywordMappingErrorType.patternTooLong,
        userFriendlyMessage: '패턴은 200자 이내로 입력해주세요.',
      );
    }

    if (isRegex) {
      if (isPatternTooComplex()) {
        return const KeywordMappingException(
          '패턴이 너무 복잡합니다.',
          KeywordMappingErrorType.patternTooComplex,
          userFriendlyMessage: '더 간단한 패턴을 사용해주세요.',
        );
      }

      try {
        RegExp(trimmedPattern, caseSensitive: caseSensitive);
      } catch (e) {
        return KeywordMappingException(
          '유효하지 않은 정규식 패턴입니다.',
          KeywordMappingErrorType.invalidRegex,
          technicalDetails: e.toString(),
          userFriendlyMessage: '정규식 문법을 확인하거나 단순 텍스트 모드를 사용해주세요.',
        );
      }
    }

    return null; // 유효함
  }

  /// 카테고리 유효성 검사
  KeywordMappingException? validateCategory() {
    final trimmedCategory = category.trim();

    if (trimmedCategory.isEmpty) {
      return const KeywordMappingException(
        '카테고리가 비어있습니다.',
        KeywordMappingErrorType.emptyCategory,
        userFriendlyMessage: '카테고리명을 입력해주세요.',
      );
    }

    if (trimmedCategory.length > 50) {
      return const KeywordMappingException(
        '카테고리명이 너무 깁니다.',
        KeywordMappingErrorType.categoryTooLong,
        userFriendlyMessage: '카테고리명은 50자 이내로 입력해주세요.',
      );
    }

    // 특수 문자 검사 (파일 시스템에서 사용할 수 없는 문자들)
    final invalidChars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
    for (final char in invalidChars) {
      if (trimmedCategory.contains(char)) {
        return KeywordMappingException(
          '카테고리명에 사용할 수 없는 문자가 포함되어 있습니다.',
          KeywordMappingErrorType.emptyCategory,
          technicalDetails: '사용할 수 없는 문자: $char',
          userFriendlyMessage: '카테고리명에는 특수문자(/ \\ : * ? " < > |)를 사용할 수 없습니다.',
        );
      }
    }

    return null; // 유효함
  }

  /// 우선순위 유효성 검사
  KeywordMappingException? validatePriority() {
    if (priority < 0) {
      return const KeywordMappingException(
        '우선순위는 0 이상이어야 합니다.',
        KeywordMappingErrorType.invalidPriority,
        userFriendlyMessage: '우선순위는 0 이상의 숫자를 입력해주세요.',
      );
    }

    if (priority > 9999) {
      return const KeywordMappingException(
        '우선순위가 너무 큽니다.',
        KeywordMappingErrorType.invalidPriority,
        userFriendlyMessage: '우선순위는 9999 이하로 설정해주세요.',
      );
    }

    return null; // 유효함
  }

  /// 전체 유효성 검사
  List<KeywordMappingException> validate() {
    final errors = <KeywordMappingException>[];

    final patternError = validatePattern();
    if (patternError != null) {
      errors.add(patternError);
    }

    final categoryError = validateCategory();
    if (categoryError != null) {
      errors.add(categoryError);
    }

    final priorityError = validatePriority();
    if (priorityError != null) {
      errors.add(priorityError);
    }

    return errors;
  }

  /// 패턴 매칭 테스트 (런타임 오류 복구 포함)
  bool testPattern(String fileName, {bool throwOnError = false}) {
    try {
      if (isRegex) {
        final regex = RegExp(pattern, caseSensitive: caseSensitive);
        return regex.hasMatch(fileName);
      } else {
        final searchText = caseSensitive ? fileName : fileName.toLowerCase();
        final searchPattern = caseSensitive ? pattern : pattern.toLowerCase();
        return searchText.contains(searchPattern);
      }
    } catch (e) {
      if (throwOnError) {
        throw KeywordMappingException(
          '패턴 매칭 중 오류가 발생했습니다.',
          KeywordMappingErrorType.runtimeRegexError,
          technicalDetails: e.toString(),
          userFriendlyMessage: '패턴을 단순화하거나 단순 텍스트 모드를 사용해주세요.',
        );
      }
      return false; // 오류 발생 시 매칭되지 않은 것으로 처리
    }
  }

  /// 안전한 패턴 매칭 (오류 복구 포함)
  bool safeTestPattern(String fileName) {
    return testPattern(fileName, throwOnError: false);
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
  final String? technicalDetails;
  final String? userFriendlyMessage;

  const KeywordMappingException(this.message, this.type, {this.technicalDetails, this.userFriendlyMessage});

  /// 사용자에게 표시할 친화적인 메시지 반환
  String get displayMessage => userFriendlyMessage ?? message;

  /// 기술적 세부사항 포함한 전체 메시지 반환
  String get fullMessage {
    if (technicalDetails != null) {
      return '$message\n기술적 세부사항: $technicalDetails';
    }
    return message;
  }

  /// 오류 타입에 따른 해결 방법 제안
  String get suggestionMessage {
    switch (type) {
      case KeywordMappingErrorType.duplicatePattern:
        return '다른 패턴을 사용하거나 기존 규칙을 수정해주세요.';
      case KeywordMappingErrorType.emptyPattern:
        return '패턴을 입력해주세요. 예: "report" 또는 "\\d{4}.*data"';
      case KeywordMappingErrorType.invalidRegex:
        return '정규식 문법을 확인하거나 단순 텍스트 모드를 사용해주세요.';
      case KeywordMappingErrorType.emptyCategory:
        return '카테고리명을 입력해주세요. 예: "보고서", "데이터", "백업"';
      case KeywordMappingErrorType.invalidPriority:
        return '우선순위는 0 이상의 정수여야 합니다.';
      case KeywordMappingErrorType.runtimeRegexError:
        return '패턴 매칭 중 오류가 발생했습니다. 패턴을 단순화하거나 수정해주세요.';
      case KeywordMappingErrorType.patternTooComplex:
        return '패턴이 너무 복잡합니다. 더 간단한 패턴을 사용해주세요.';
      case KeywordMappingErrorType.categoryTooLong:
        return '카테고리명이 너무 깁니다. 50자 이내로 입력해주세요.';
      case KeywordMappingErrorType.patternTooLong:
        return '패턴이 너무 깁니다. 200자 이내로 입력해주세요.';
    }
  }

  /// 오류 복구를 위한 제안된 액션
  List<String> get recoveryActions {
    switch (type) {
      case KeywordMappingErrorType.duplicatePattern:
        return ['기존 규칙 수정', '다른 패턴 사용', '기존 규칙 삭제 후 재생성'];
      case KeywordMappingErrorType.emptyPattern:
        return ['패턴 입력', '예시 패턴 사용'];
      case KeywordMappingErrorType.invalidRegex:
        return ['정규식 문법 수정', '단순 텍스트 모드 사용', '패턴 테스트 실행'];
      case KeywordMappingErrorType.emptyCategory:
        return ['카테고리명 입력', '기존 카테고리 선택'];
      case KeywordMappingErrorType.invalidPriority:
        return ['우선순위 값 수정', '자동 우선순위 사용'];
      case KeywordMappingErrorType.runtimeRegexError:
        return ['패턴 단순화', '단순 텍스트 모드 사용', '패턴 테스트 실행'];
      case KeywordMappingErrorType.patternTooComplex:
        return ['패턴 단순화', '여러 규칙으로 분할'];
      case KeywordMappingErrorType.categoryTooLong:
        return ['카테고리명 단축', '약어 사용'];
      case KeywordMappingErrorType.patternTooLong:
        return ['패턴 단축', '여러 규칙으로 분할'];
    }
  }

  @override
  String toString() => 'KeywordMappingException: $message';
}

/// 키워드 매핑 오류 타입
enum KeywordMappingErrorType {
  duplicatePattern,
  emptyPattern,
  invalidRegex,
  emptyCategory,
  invalidPriority,
  runtimeRegexError,
  patternTooComplex,
  categoryTooLong,
  patternTooLong,
}
