import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FileCategoryConfigProvider Keyword Mapping Tests', () {
    late ProviderContainer container;
    late SharedPreferences mockPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();

      container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)]);
    });

    tearDown(() {
      container.dispose();
    });

    test('should add keyword mapping successfully', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const mapping = KeywordMapping(
        pattern: 'report',
        category: '보고서',
        isRegex: false,
        caseSensitive: false,
        priority: 0,
      );

      await notifier.addKeywordMapping(mapping);

      final config = container.read(fileCategoryConfigProvider);
      expect(config.keywordMappings.length, 1);
      expect(config.keywordMappings.first.pattern, 'report');
      expect(config.keywordMappings.first.category, '보고서');
    });

    test('should throw exception for duplicate pattern', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const mapping1 = KeywordMapping(
        pattern: 'report',
        category: '보고서',
        isRegex: false,
        caseSensitive: false,
        priority: 0,
      );

      const mapping2 = KeywordMapping(
        pattern: 'report',
        category: '문서',
        isRegex: false,
        caseSensitive: false,
        priority: 1,
      );

      await notifier.addKeywordMapping(mapping1);

      expect(() => notifier.addKeywordMapping(mapping2), throwsA(isA<KeywordMappingException>()));
    });

    test('should remove keyword mapping successfully', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const mapping = KeywordMapping(
        pattern: 'report',
        category: '보고서',
        isRegex: false,
        caseSensitive: false,
        priority: 0,
      );

      await notifier.addKeywordMapping(mapping);
      expect(container.read(fileCategoryConfigProvider).keywordMappings.length, 1);

      await notifier.removeKeywordMapping('report');
      expect(container.read(fileCategoryConfigProvider).keywordMappings.length, 0);
    });

    test('should update keyword mapping successfully', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const originalMapping = KeywordMapping(
        pattern: 'report',
        category: '보고서',
        isRegex: false,
        caseSensitive: false,
        priority: 0,
      );

      const updatedMapping = KeywordMapping(
        pattern: 'report',
        category: '문서',
        isRegex: true,
        caseSensitive: true,
        priority: 1,
      );

      await notifier.addKeywordMapping(originalMapping);
      await notifier.updateKeywordMapping('report', updatedMapping);

      final config = container.read(fileCategoryConfigProvider);
      final mapping = config.keywordMappings.first;

      expect(mapping.category, '문서');
      expect(mapping.isRegex, true);
      expect(mapping.caseSensitive, true);
      expect(mapping.priority, 1);
    });

    test('should validate keyword patterns correctly', () {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      // Valid simple text pattern
      expect(notifier.validateKeywordPattern('report'), isNull);

      // Empty pattern
      expect(notifier.validateKeywordPattern(''), isNotNull);
      expect(notifier.validateKeywordPattern('   '), isNotNull);

      // Valid regex pattern
      expect(notifier.validateKeywordPattern(r'\d{4}.*report', isRegex: true), isNull);

      // Invalid regex pattern
      expect(notifier.validateKeywordPattern('[invalid', isRegex: true), isNotNull);
    });

    test('should test keyword patterns correctly', () {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      // Simple text pattern
      const textMapping = KeywordMapping(pattern: 'report', category: '보고서', isRegex: false, caseSensitive: false);

      expect(notifier.testKeywordPattern('monthly_report.pdf', textMapping), true);
      expect(notifier.testKeywordPattern('REPORT_2024.docx', textMapping), true);
      expect(notifier.testKeywordPattern('data.csv', textMapping), false);

      // Regex pattern
      const regexMapping = KeywordMapping(
        pattern: r'\d{4}.*report',
        category: '연도별 보고서',
        isRegex: true,
        caseSensitive: false,
      );

      expect(notifier.testKeywordPattern('2024_annual_report.pdf', regexMapping), true);
      expect(notifier.testKeywordPattern('2023-monthly-report.docx', regexMapping), true);
      expect(notifier.testKeywordPattern('report_2024.pdf', regexMapping), false);
    });

    test('should find matching keyword mapping by priority', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const mapping1 = KeywordMapping(pattern: 'report', category: '보고서', priority: 1);

      const mapping2 = KeywordMapping(
        pattern: 'annual',
        category: '연간자료',
        priority: 0, // Higher priority (lower number)
      );

      await notifier.addKeywordMapping(mapping1);
      await notifier.addKeywordMapping(mapping2);

      // Should match higher priority mapping first
      final result = notifier.findMatchingKeywordMapping('annual_report.pdf');
      expect(result?.category, '연간자료');
    });

    test('should return sorted keyword mappings by priority', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const mapping1 = KeywordMapping(pattern: 'c', category: 'C', priority: 2);
      const mapping2 = KeywordMapping(pattern: 'a', category: 'A', priority: 0);
      const mapping3 = KeywordMapping(pattern: 'b', category: 'B', priority: 1);

      await notifier.addKeywordMapping(mapping1);
      await notifier.addKeywordMapping(mapping2);
      await notifier.addKeywordMapping(mapping3);

      final sorted = container.read(sortedKeywordMappingsProvider);
      expect(sorted.length, 3);
      expect(sorted[0].category, 'A'); // priority 0
      expect(sorted[1].category, 'B'); // priority 1
      expect(sorted[2].category, 'C'); // priority 2
    });

    test('should filter custom keyword mappings', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const customMapping = KeywordMapping(pattern: 'custom', category: '사용자정의', isCustom: true);

      const systemMapping = KeywordMapping(pattern: 'system', category: '시스템', isCustom: false);

      await notifier.addKeywordMapping(customMapping);
      await notifier.addKeywordMapping(systemMapping);

      final customMappings = container.read(customKeywordMappingsProvider);
      expect(customMappings.length, 1);
      expect(customMappings.first.pattern, 'custom');
    });

    test('should filter regex keyword mappings', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const regexMapping = KeywordMapping(pattern: r'\d+', category: '숫자', isRegex: true);

      const textMapping = KeywordMapping(pattern: 'text', category: '텍스트', isRegex: false);

      await notifier.addKeywordMapping(regexMapping);
      await notifier.addKeywordMapping(textMapping);

      final regexMappings = container.read(regexKeywordMappingsProvider);
      final textMappings = container.read(textKeywordMappingsProvider);

      expect(regexMappings.length, 1);
      expect(regexMappings.first.pattern, r'\d+');

      expect(textMappings.length, 1);
      expect(textMappings.first.pattern, 'text');
    });

    test('should check for duplicate patterns correctly', () async {
      final notifier = container.read(fileCategoryConfigProvider.notifier);

      const mapping = KeywordMapping(pattern: 'report', category: '보고서');

      await notifier.addKeywordMapping(mapping);

      expect(notifier.isDuplicatePattern('report'), true);
      expect(notifier.isDuplicatePattern('data'), false);
      expect(notifier.isDuplicatePattern('report', excludePattern: 'report'), false);
    });
  });
}
