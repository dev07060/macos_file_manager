/// 파일 정리 결과를 나타내는 모델
class FileOrganizationResult {
  final String filePath;
  final String fileName;
  final String category;
  final FileOrganizationMethod method;
  final String? matchedPattern;
  final String? matchedExtension;

  const FileOrganizationResult({
    required this.filePath,
    required this.fileName,
    required this.category,
    required this.method,
    this.matchedPattern,
    this.matchedExtension,
  });

  /// 키워드 기반 정리 결과 생성
  factory FileOrganizationResult.keyword({
    required String filePath,
    required String fileName,
    required String category,
    required String matchedPattern,
  }) {
    return FileOrganizationResult(
      filePath: filePath,
      fileName: fileName,
      category: category,
      method: FileOrganizationMethod.keyword,
      matchedPattern: matchedPattern,
    );
  }

  /// 확장자 기반 정리 결과 생성
  factory FileOrganizationResult.extension({
    required String filePath,
    required String fileName,
    required String category,
    required String matchedExtension,
  }) {
    return FileOrganizationResult(
      filePath: filePath,
      fileName: fileName,
      category: category,
      method: FileOrganizationMethod.extension,
      matchedExtension: matchedExtension,
    );
  }

  /// 기타 정리 결과 생성
  factory FileOrganizationResult.other({required String filePath, required String fileName, required String category}) {
    return FileOrganizationResult(
      filePath: filePath,
      fileName: fileName,
      category: category,
      method: FileOrganizationMethod.other,
    );
  }

  @override
  String toString() {
    switch (method) {
      case FileOrganizationMethod.keyword:
        return '$fileName -> $category (키워드: "$matchedPattern")';
      case FileOrganizationMethod.extension:
        return '$fileName -> $category (확장자: .$matchedExtension)';
      case FileOrganizationMethod.other:
        return '$fileName -> $category (기타)';
    }
  }
}

/// 파일 정리 방법을 나타내는 열거형
enum FileOrganizationMethod {
  keyword, // 키워드 기반
  extension, // 확장자 기반
  other, // 기타
}

/// 전체 파일 정리 결과 요약
class FileOrganizationSummary {
  final List<FileOrganizationResult> results;
  final DateTime timestamp;

  const FileOrganizationSummary({required this.results, required this.timestamp});

  /// 키워드 기반으로 정리된 파일 수
  int get keywordBasedCount => results.where((r) => r.method == FileOrganizationMethod.keyword).length;

  /// 확장자 기반으로 정리된 파일 수
  int get extensionBasedCount => results.where((r) => r.method == FileOrganizationMethod.extension).length;

  /// 기타 방법으로 정리된 파일 수
  int get otherCount => results.where((r) => r.method == FileOrganizationMethod.other).length;

  /// 전체 정리된 파일 수
  int get totalCount => results.length;

  /// 카테고리별 파일 수
  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final result in results) {
      counts[result.category] = (counts[result.category] ?? 0) + 1;
    }
    return counts;
  }

  /// 키워드별 매칭된 파일 수
  Map<String, int> get keywordMatchCounts {
    final counts = <String, int>{};
    for (final result in results.where((r) => r.method == FileOrganizationMethod.keyword)) {
      final pattern = result.matchedPattern!;
      counts[pattern] = (counts[pattern] ?? 0) + 1;
    }
    return counts;
  }

  /// 확장자별 매칭된 파일 수
  Map<String, int> get extensionMatchCounts {
    final counts = <String, int>{};
    for (final result in results.where((r) => r.method == FileOrganizationMethod.extension)) {
      final extension = result.matchedExtension!;
      counts[extension] = (counts[extension] ?? 0) + 1;
    }
    return counts;
  }

  /// 키워드 기반 정리가 있었는지 확인
  bool get hasKeywordBasedResults => keywordBasedCount > 0;

  /// 확장자 기반 정리가 있었는지 확인
  bool get hasExtensionBasedResults => extensionBasedCount > 0;

  /// 요약 메시지 생성
  String generateSummaryMessage() {
    if (totalCount == 0) {
      return '정리할 파일이 없습니다.';
    }

    final buffer = StringBuffer();
    buffer.writeln('총 $totalCount개 파일이 정리되었습니다.');

    if (hasKeywordBasedResults) {
      buffer.writeln('• 키워드 기반: $keywordBasedCount개');
    }

    if (hasExtensionBasedResults) {
      buffer.writeln('• 확장자 기반: $extensionBasedCount개');
    }

    if (otherCount > 0) {
      buffer.writeln('• 기타: $otherCount개');
    }

    return buffer.toString().trim();
  }

  /// 상세 보고서 생성
  String generateDetailedReport() {
    if (totalCount == 0) {
      return '정리할 파일이 없습니다.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== 파일 정리 결과 보고서 ===');
    buffer.writeln('정리 시간: ${timestamp.toString()}');
    buffer.writeln('총 파일 수: $totalCount개\n');

    // 키워드 기반 정리 결과
    if (hasKeywordBasedResults) {
      buffer.writeln('📝 키워드 기반 정리 ($keywordBasedCount개):');
      final keywordResults = results.where((r) => r.method == FileOrganizationMethod.keyword).toList();

      // 키워드별 그룹화
      final keywordGroups = <String, List<FileOrganizationResult>>{};
      for (final result in keywordResults) {
        final pattern = result.matchedPattern!;
        keywordGroups.putIfAbsent(pattern, () => []).add(result);
      }

      for (final entry in keywordGroups.entries) {
        final pattern = entry.key;
        final files = entry.value;
        buffer.writeln('  • 패턴 "$pattern": ${files.length}개');
        for (final file in files) {
          buffer.writeln('    - ${file.fileName} → ${file.category}');
        }
      }
      buffer.writeln();
    }

    // 확장자 기반 정리 결과
    if (hasExtensionBasedResults) {
      buffer.writeln('📄 확장자 기반 정리 ($extensionBasedCount개):');
      final extensionResults = results.where((r) => r.method == FileOrganizationMethod.extension).toList();

      // 확장자별 그룹화
      final extensionGroups = <String, List<FileOrganizationResult>>{};
      for (final result in extensionResults) {
        final extension = result.matchedExtension!;
        extensionGroups.putIfAbsent(extension, () => []).add(result);
      }

      for (final entry in extensionGroups.entries) {
        final extension = entry.key;
        final files = entry.value;
        buffer.writeln('  • 확장자 ".$extension": ${files.length}개');
        for (final file in files) {
          buffer.writeln('    - ${file.fileName} → ${file.category}');
        }
      }
      buffer.writeln();
    }

    // 기타 정리 결과
    if (otherCount > 0) {
      buffer.writeln('📋 기타 정리 ($otherCount개):');
      final otherResults = results.where((r) => r.method == FileOrganizationMethod.other).toList();
      for (final result in otherResults) {
        buffer.writeln('  • ${result.fileName} → ${result.category}');
      }
      buffer.writeln();
    }

    // 카테고리별 요약
    buffer.writeln('📊 카테고리별 요약:');
    final sortedCategories = categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      buffer.writeln('  • ${entry.key}: ${entry.value}개');
    }

    return buffer.toString();
  }
}
