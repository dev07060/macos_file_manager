import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';

void main() {
  group('FileOrganizationResult', () {
    test('should create keyword-based result correctly', () {
      final result = FileOrganizationResult.keyword(
        filePath: '/test/report.pdf',
        fileName: 'report.pdf',
        category: '보고서',
        matchedPattern: 'report',
      );

      expect(result.method, FileOrganizationMethod.keyword);
      expect(result.category, '보고서');
      expect(result.matchedPattern, 'report');
      expect(result.matchedExtension, isNull);
      expect(result.toString(), 'report.pdf -> 보고서 (키워드: "report")');
    });

    test('should create extension-based result correctly', () {
      final result = FileOrganizationResult.extension(
        filePath: '/test/document.pdf',
        fileName: 'document.pdf',
        category: '문서',
        matchedExtension: 'pdf',
      );

      expect(result.method, FileOrganizationMethod.extension);
      expect(result.category, '문서');
      expect(result.matchedExtension, 'pdf');
      expect(result.matchedPattern, isNull);
      expect(result.toString(), 'document.pdf -> 문서 (확장자: .pdf)');
    });

    test('should create other result correctly', () {
      final result = FileOrganizationResult.other(
        filePath: '/test/unknown.xyz',
        fileName: 'unknown.xyz',
        category: '기타',
      );

      expect(result.method, FileOrganizationMethod.other);
      expect(result.category, '기타');
      expect(result.matchedPattern, isNull);
      expect(result.matchedExtension, isNull);
      expect(result.toString(), 'unknown.xyz -> 기타 (기타)');
    });
  });

  group('FileOrganizationSummary', () {
    late List<FileOrganizationResult> testResults;

    setUp(() {
      testResults = [
        FileOrganizationResult.keyword(
          filePath: '/test/report1.pdf',
          fileName: 'report1.pdf',
          category: '보고서',
          matchedPattern: 'report',
        ),
        FileOrganizationResult.keyword(
          filePath: '/test/report2.pdf',
          fileName: 'report2.pdf',
          category: '보고서',
          matchedPattern: 'report',
        ),
        FileOrganizationResult.extension(
          filePath: '/test/document.pdf',
          fileName: 'document.pdf',
          category: '문서',
          matchedExtension: 'pdf',
        ),
        FileOrganizationResult.other(filePath: '/test/unknown.xyz', fileName: 'unknown.xyz', category: '기타'),
      ];
    });

    test('should calculate counts correctly', () {
      final summary = FileOrganizationSummary(results: testResults, timestamp: DateTime.now());

      expect(summary.totalCount, 4);
      expect(summary.keywordBasedCount, 2);
      expect(summary.extensionBasedCount, 1);
      expect(summary.otherCount, 1);
      expect(summary.hasKeywordBasedResults, true);
      expect(summary.hasExtensionBasedResults, true);
    });

    test('should generate category counts correctly', () {
      final summary = FileOrganizationSummary(results: testResults, timestamp: DateTime.now());

      final categoryCounts = summary.categoryCounts;
      expect(categoryCounts['보고서'], 2);
      expect(categoryCounts['문서'], 1);
      expect(categoryCounts['기타'], 1);
    });

    test('should generate keyword match counts correctly', () {
      final summary = FileOrganizationSummary(results: testResults, timestamp: DateTime.now());

      final keywordCounts = summary.keywordMatchCounts;
      expect(keywordCounts['report'], 2);
    });

    test('should generate extension match counts correctly', () {
      final summary = FileOrganizationSummary(results: testResults, timestamp: DateTime.now());

      final extensionCounts = summary.extensionMatchCounts;
      expect(extensionCounts['pdf'], 1);
    });

    test('should generate summary message correctly', () {
      final summary = FileOrganizationSummary(results: testResults, timestamp: DateTime.now());

      final message = summary.generateSummaryMessage();
      expect(message, contains('총 4개 파일이 정리되었습니다.'));
      expect(message, contains('키워드 기반: 2개'));
      expect(message, contains('확장자 기반: 1개'));
      expect(message, contains('기타: 1개'));
    });

    test('should generate detailed report correctly', () {
      final summary = FileOrganizationSummary(results: testResults, timestamp: DateTime.now());

      final report = summary.generateDetailedReport();
      expect(report, contains('=== 파일 정리 결과 보고서 ==='));
      expect(report, contains('총 파일 수: 4개'));
      expect(report, contains('📝 키워드 기반 정리 (2개)'));
      expect(report, contains('패턴 "report": 2개'));
      expect(report, contains('📄 확장자 기반 정리 (1개)'));
      expect(report, contains('확장자 ".pdf": 1개'));
      expect(report, contains('📋 기타 정리 (1개)'));
      expect(report, contains('📊 카테고리별 요약'));
    });

    test('should handle empty results correctly', () {
      final summary = FileOrganizationSummary(results: [], timestamp: DateTime.now());

      expect(summary.totalCount, 0);
      expect(summary.hasKeywordBasedResults, false);
      expect(summary.hasExtensionBasedResults, false);
      expect(summary.generateSummaryMessage(), '정리할 파일이 없습니다.');
      expect(summary.generateDetailedReport(), '정리할 파일이 없습니다.');
    });
  });
}
