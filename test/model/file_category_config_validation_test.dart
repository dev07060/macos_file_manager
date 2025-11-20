import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';

void main() {
  group('FileCategoryConfig Enhanced Validation Tests', () {
    test('should add valid keyword mapping', () {
      final config = FileCategoryConfig();
      final mapping = KeywordMapping(pattern: 'test', category: 'test_category');

      final updatedConfig = config.addKeywordMapping(mapping);
      expect(updatedConfig.keywordMappings.length, 1);
      expect(updatedConfig.keywordMappings.first.pattern, 'test');
    });

    test('should throw exception for duplicate pattern', () {
      final mapping1 = KeywordMapping(pattern: 'test', category: 'category1');
      final mapping2 = KeywordMapping(pattern: 'test', category: 'category2');

      final config = FileCategoryConfig(keywordMappings: [mapping1]);

      expect(() => config.addKeywordMapping(mapping2), throwsA(isA<KeywordMappingException>()));
    });

    test('should throw exception for invalid mapping', () {
      final config = FileCategoryConfig();
      final invalidMapping = KeywordMapping(
        pattern: '', // Empty pattern
        category: 'test',
      );

      expect(() => config.addKeywordMapping(invalidMapping), throwsA(isA<KeywordMappingException>()));
    });

    test('should update existing keyword mapping', () {
      final originalMapping = KeywordMapping(pattern: 'test', category: 'old_category');
      final config = FileCategoryConfig(keywordMappings: [originalMapping]);

      final updatedMapping = KeywordMapping(pattern: 'test', category: 'new_category');
      final updatedConfig = config.updateKeywordMapping('test', updatedMapping);

      expect(updatedConfig.keywordMappings.length, 1);
      expect(updatedConfig.keywordMappings.first.category, 'new_category');
    });

    test('should throw exception when updating to duplicate pattern', () {
      final mapping1 = KeywordMapping(pattern: 'test1', category: 'category1');
      final mapping2 = KeywordMapping(pattern: 'test2', category: 'category2');
      final config = FileCategoryConfig(keywordMappings: [mapping1, mapping2]);

      final updatedMapping = KeywordMapping(pattern: 'test1', category: 'category2'); // Duplicate pattern

      expect(() => config.updateKeywordMapping('test2', updatedMapping), throwsA(isA<KeywordMappingException>()));
    });

    test('should remove keyword mapping', () {
      final mapping = KeywordMapping(pattern: 'test', category: 'category');
      final config = FileCategoryConfig(keywordMappings: [mapping]);

      final updatedConfig = config.removeKeywordMapping('test');
      expect(updatedConfig.keywordMappings.length, 0);
    });

    test('should validate all keyword mappings', () {
      final validMapping = KeywordMapping(pattern: 'valid', category: 'category');
      final invalidMapping = KeywordMapping(pattern: '', category: 'category'); // Empty pattern
      final duplicateMapping = KeywordMapping(pattern: 'valid', category: 'category2'); // Duplicate pattern

      final config = FileCategoryConfig(keywordMappings: [validMapping, invalidMapping, duplicateMapping]);
      final errors = config.validateKeywordMappings();

      expect(errors.length, greaterThan(0));
      expect(errors.any((e) => e.type == KeywordMappingErrorType.emptyPattern), true);
      expect(errors.any((e) => e.type == KeywordMappingErrorType.duplicatePattern), true);
    });

    test('should return sorted keyword mappings by priority', () {
      final mapping1 = KeywordMapping(pattern: 'test1', category: 'category1', priority: 2);
      final mapping2 = KeywordMapping(pattern: 'test2', category: 'category2', priority: 1);
      final mapping3 = KeywordMapping(pattern: 'test3', category: 'category3', priority: 3);

      final config = FileCategoryConfig(keywordMappings: [mapping1, mapping2, mapping3]);
      final sortedMappings = config.getKeywordMappingsSortedByPriority();

      expect(sortedMappings.length, 3);
      expect(sortedMappings[0].pattern, 'test2'); // Priority 1
      expect(sortedMappings[1].pattern, 'test1'); // Priority 2
      expect(sortedMappings[2].pattern, 'test3'); // Priority 3
    });

    test('should check if keyword mapping exists', () {
      final mapping = KeywordMapping(pattern: 'test', category: 'category');
      final config = FileCategoryConfig(keywordMappings: [mapping]);

      expect(config.hasKeywordMapping('test'), true);
      expect(config.hasKeywordMapping('nonexistent'), false);
    });

    test('should get specific keyword mapping', () {
      final mapping = KeywordMapping(pattern: 'test', category: 'category');
      final config = FileCategoryConfig(keywordMappings: [mapping]);

      final foundMapping = config.getKeywordMapping('test');
      expect(foundMapping, isNotNull);
      expect(foundMapping!.pattern, 'test');
      expect(foundMapping.category, 'category');

      final notFoundMapping = config.getKeywordMapping('nonexistent');
      expect(notFoundMapping, isNull);
    });
  });

  group('FileCategoryConfig JSON Serialization Tests', () {
    test('should serialize and deserialize with keyword mappings', () {
      final mapping1 = KeywordMapping(
        pattern: 'test1',
        category: 'category1',
        isRegex: true,
        caseSensitive: true,
        priority: 1,
      );
      final mapping2 = KeywordMapping(
        pattern: 'test2',
        category: 'category2',
        isRegex: false,
        caseSensitive: false,
        priority: 2,
      );

      final originalConfig = FileCategoryConfig(
        extensionCategories: {'txt': 'documents'},
        keywordMappings: [mapping1, mapping2],
      );

      final json = originalConfig.toJson();
      final deserializedConfig = FileCategoryConfig.fromJson(json);

      expect(deserializedConfig.extensionCategories['txt'], 'documents');
      expect(deserializedConfig.keywordMappings.length, 2);

      final deserializedMapping1 = deserializedConfig.keywordMappings[0];
      expect(deserializedMapping1.pattern, 'test1');
      expect(deserializedMapping1.category, 'category1');
      expect(deserializedMapping1.isRegex, true);
      expect(deserializedMapping1.caseSensitive, true);
      expect(deserializedMapping1.priority, 1);

      final deserializedMapping2 = deserializedConfig.keywordMappings[1];
      expect(deserializedMapping2.pattern, 'test2');
      expect(deserializedMapping2.category, 'category2');
      expect(deserializedMapping2.isRegex, false);
      expect(deserializedMapping2.caseSensitive, false);
      expect(deserializedMapping2.priority, 2);
    });
  });
}
