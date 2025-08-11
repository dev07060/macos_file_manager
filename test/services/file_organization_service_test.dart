import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';
import 'package:macos_file_manager/services/file_organization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FileOrganizationService Keyword Categorization Tests', () {
    late ProviderContainer container;
    late FileOrganizationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      service = container.read(fileOrganizationServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('_categorizeByKeyword', () {
      test('should categorize file by simple text pattern', () {
        final config = FileCategoryConfig(
          keywordMappings: [
            const KeywordMapping(pattern: 'report', category: '보고서', isRegex: false),
            const KeywordMapping(pattern: 'data', category: '데이터', isRegex: false),
          ],
        );

        expect(service.organizeFileByKeyword('monthly_report.pdf', '', config), '보고서');
        expect(service.organizeFileByKeyword('user_data.csv', '', config), '데이터');
        expect(service.organizeFileByKeyword('random_file.txt', '', config), '기타');
      });

      test('should categorize file by regex pattern', () {
        final config = FileCategoryConfig(
          keywordMappings: [
            const KeywordMapping(pattern: r'\d{4}.*report', category: '연도별 보고서', isRegex: true),
            const KeywordMapping(pattern: r'backup_\w+_\d+', category: '백업 파일', isRegex: true),
          ],
        );

        expect(service.organizeFileByKeyword('2024_annual_report.pdf', '', config), '연도별 보고서');
        expect(service.organizeFileByKeyword('backup_database_20240101.sql', '', config), '백업 파일');
        expect(service.organizeFileByKeyword('report_2024.pdf', '', config), '기타');
      });

      test('should respect case sensitivity settings', () {
        final config = FileCategoryConfig(
          keywordMappings: [
            const KeywordMapping(pattern: 'Report', category: '대소문자구분', isRegex: false, caseSensitive: true),
            const KeywordMapping(pattern: 'data', category: '대소문자무시', isRegex: false, caseSensitive: false),
          ],
        );

        expect(service.organizeFileByKeyword('Monthly_Report.pdf', '', config), '대소문자구분');
        expect(service.organizeFileByKeyword('monthly_report.pdf', '', config), '기타');
        expect(service.organizeFileByKeyword('User_DATA.csv', '', config), '대소문자무시');
        expect(service.organizeFileByKeyword('user_data.csv', '', config), '대소문자무시');
      });

      test('should respect priority order', () {
        final config = FileCategoryConfig(
          keywordMappings: [
            const KeywordMapping(pattern: 'report', category: '낮은우선순위', priority: 10),
            const KeywordMapping(pattern: 'report', category: '높은우선순위', priority: 1),
          ],
        );

        expect(service.organizeFileByKeyword('test_report.pdf', '', config), '높은우선순위');
      });

      test('should handle invalid regex patterns gracefully', () {
        final config = FileCategoryConfig(
          keywordMappings: [
            const KeywordMapping(pattern: '[invalid_regex', category: '잘못된정규식', isRegex: true),
            const KeywordMapping(pattern: 'valid', category: '유효한패턴', isRegex: false),
          ],
        );

        // 잘못된 정규식은 무시되고 다음 패턴이 적용되어야 함
        expect(service.organizeFileByKeyword('valid_file.txt', '', config), '유효한패턴');
        expect(service.organizeFileByKeyword('test_file.txt', '', config), '기타');
      });

      test('should return null when no patterns match', () {
        final config = FileCategoryConfig(
          keywordMappings: [
            const KeywordMapping(pattern: 'report', category: '보고서'),
            const KeywordMapping(pattern: 'data', category: '데이터'),
          ],
        );

        expect(service.organizeFileByKeyword('random_file.txt', '', config), '기타');
      });

      test('should handle empty keyword mappings', () {
        final config = FileCategoryConfig(keywordMappings: []);

        expect(service.organizeFileByKeyword('any_file.txt', '', config), '기타');
      });
    });

    group('keyword prioritization', () {
      test('should prioritize keyword matching over extension matching', () {
        final config = FileCategoryConfig(
          extensionCategories: {'pdf': '문서'},
          keywordMappings: [const KeywordMapping(pattern: 'report', category: '보고서')],
        );

        // 키워드 매칭이 확장자 매칭보다 우선해야 함
        expect(service.organizeFileByKeyword('report.pdf', '', config), '보고서');
        expect(service.organizeFileByKeyword('document.pdf', '', config), '기타');
      });
    });
  });
}
