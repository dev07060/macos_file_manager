import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';

void main() {
  group('KeywordMapping Enhanced Validation Tests', () {
    test('should validate empty pattern', () {
      final mapping = KeywordMapping(pattern: '', category: 'test');

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.emptyPattern);
      expect(errors.first.displayMessage, '패턴을 입력해주세요.');
    });

    test('should validate empty category', () {
      final mapping = KeywordMapping(pattern: 'test', category: '');

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.emptyCategory);
      expect(errors.first.displayMessage, '카테고리명을 입력해주세요.');
    });

    test('should validate invalid regex pattern', () {
      final mapping = KeywordMapping(pattern: '[invalid regex', category: 'test', isRegex: true);

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.invalidRegex);
    });

    test('should validate pattern too long', () {
      final mapping = KeywordMapping(
        pattern: 'a' * 201, // 201 characters
        category: 'test',
      );

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.patternTooLong);
    });

    test('should validate category too long', () {
      final mapping = KeywordMapping(
        pattern: 'test',
        category: 'a' * 51, // 51 characters
      );

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.categoryTooLong);
    });

    test('should validate invalid priority', () {
      final mapping = KeywordMapping(pattern: 'test', category: 'test', priority: -1);

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.invalidPriority);
    });

    test('should validate category with invalid characters', () {
      final mapping = KeywordMapping(
        pattern: 'test',
        category: 'test/category', // Contains invalid character '/'
      );

      final errors = mapping.validate();
      expect(errors.length, 1);
      expect(errors.first.type, KeywordMappingErrorType.emptyCategory);
      expect(errors.first.displayMessage.contains('특수문자'), true);
    });

    test('should pass validation for valid mapping', () {
      final mapping = KeywordMapping(
        pattern: 'test',
        category: 'test',
        isRegex: false,
        caseSensitive: false,
        priority: 0,
      );

      final errors = mapping.validate();
      expect(errors.length, 0);
    });

    test('should pass validation for valid regex mapping', () {
      final mapping = KeywordMapping(
        pattern: r'\d{4}.*report',
        category: 'reports',
        isRegex: true,
        caseSensitive: false,
        priority: 1,
      );

      final errors = mapping.validate();
      expect(errors.length, 0);
    });
  });

  group('KeywordMapping Pattern Testing', () {
    test('should test simple text pattern matching', () {
      final mapping = KeywordMapping(pattern: 'report', category: 'reports', isRegex: false, caseSensitive: false);

      expect(mapping.safeTestPattern('annual_report.pdf'), true);
      expect(mapping.safeTestPattern('REPORT_2024.docx'), true);
      expect(mapping.safeTestPattern('data.csv'), false);
    });

    test('should test case sensitive text pattern matching', () {
      final mapping = KeywordMapping(pattern: 'Report', category: 'reports', isRegex: false, caseSensitive: true);

      expect(mapping.safeTestPattern('annual_Report.pdf'), true);
      expect(mapping.safeTestPattern('annual_report.pdf'), false);
      expect(mapping.safeTestPattern('REPORT_2024.docx'), false);
    });

    test('should test regex pattern matching', () {
      final mapping = KeywordMapping(
        pattern: r'\d{4}.*report',
        category: 'reports',
        isRegex: true,
        caseSensitive: false,
      );

      expect(mapping.safeTestPattern('2024_annual_report.pdf'), true);
      expect(mapping.safeTestPattern('2023_quarterly_report.docx'), true);
      expect(mapping.safeTestPattern('annual_report.pdf'), false);
      expect(mapping.safeTestPattern('report_2024.pdf'), false);
    });

    test('should handle invalid regex gracefully', () {
      final mapping = KeywordMapping(pattern: '[invalid regex', category: 'test', isRegex: true);

      // Should not throw exception, should return false
      expect(mapping.safeTestPattern('test_file.txt'), false);
    });

    test('should throw exception when requested', () {
      final mapping = KeywordMapping(pattern: '[invalid regex', category: 'test', isRegex: true);

      expect(() => mapping.testPattern('test_file.txt', throwOnError: true), throwsA(isA<KeywordMappingException>()));
    });
  });

  group('KeywordMappingException Tests', () {
    test('should provide user-friendly messages', () {
      const exception = KeywordMappingException(
        'Technical error message',
        KeywordMappingErrorType.invalidRegex,
        userFriendlyMessage: 'User-friendly message',
        technicalDetails: 'Technical details',
      );

      expect(exception.displayMessage, 'User-friendly message');
      expect(exception.fullMessage, 'Technical error message\n기술적 세부사항: Technical details');
      expect(exception.suggestionMessage.isNotEmpty, true);
      expect(exception.recoveryActions.isNotEmpty, true);
    });

    test('should provide appropriate suggestions for different error types', () {
      const duplicateError = KeywordMappingException('Duplicate pattern', KeywordMappingErrorType.duplicatePattern);

      const regexError = KeywordMappingException('Invalid regex', KeywordMappingErrorType.invalidRegex);

      expect(duplicateError.suggestionMessage.contains('다른 패턴'), true);
      expect(regexError.suggestionMessage.contains('정규식 문법'), true);
    });
  });
}
