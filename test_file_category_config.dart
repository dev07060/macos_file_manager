import 'package:flutter/material.dart';

import 'lib/model/file_category_config.dart';
import 'lib/model/keyword_mapping.dart';

void main() {
  debugPrint('Testing FileCategoryConfig with keyword mappings...');

  // Test 1: Create config with keyword mappings
  final config = FileCategoryConfig(
    extensionCategories: {'pdf': '문서', 'jpg': '이미지'},
    keywordMappings: [
      const KeywordMapping(pattern: 'report', category: '보고서', priority: 0),
      const KeywordMapping(pattern: 'data', category: '데이터', priority: 1),
    ],
  );

  debugPrint('✓ Created config with ${config.keywordMappings.length} keyword mappings');

  // Test 2: Add keyword mapping
  try {
    final updatedConfig = config.addKeywordMapping(
      const KeywordMapping(pattern: 'backup', category: '백업', priority: 2),
    );
    debugPrint('✓ Added keyword mapping successfully');
    debugPrint('  Total mappings: ${updatedConfig.keywordMappings.length}');
  } catch (e) {
    debugPrint('✗ Failed to add keyword mapping: $e');
  }

  // Test 3: Test duplicate pattern validation
  try {
    config.addKeywordMapping(const KeywordMapping(pattern: 'report', category: '다른카테고리', priority: 3));
    debugPrint('✗ Should have thrown duplicate pattern error');
  } catch (e) {
    debugPrint('✓ Correctly caught duplicate pattern error: $e');
  }

  // Test 4: Test priority sorting
  final sortedMappings = config.getKeywordMappingsSortedByPriority();
  debugPrint('✓ Sorted mappings by priority:');
  for (final mapping in sortedMappings) {
    debugPrint('  Priority ${mapping.priority}: ${mapping.pattern} -> ${mapping.category}');
  }

  // Test 5: Test JSON serialization
  final json = config.toJson();
  final fromJson = FileCategoryConfig.fromJson(json);

  if (config == fromJson) {
    debugPrint('✓ JSON serialization/deserialization works correctly');
  } else {
    debugPrint('✗ JSON serialization/deserialization failed');
  }

  // Test 6: Test regex validation
  try {
    config.addKeywordMapping(const KeywordMapping(pattern: '[invalid', category: '테스트', isRegex: true));
    debugPrint('✗ Should have thrown invalid regex error');
  } catch (e) {
    debugPrint('✓ Correctly caught invalid regex error: $e');
  }

  // Test 7: Test update mapping
  try {
    final updatedConfig = config.updateKeywordMapping(
      'data',
      const KeywordMapping(pattern: 'data_files', category: '데이터파일', priority: 1),
    );
    final updatedMapping = updatedConfig.getKeywordMapping('data_files');
    if (updatedMapping != null && updatedMapping.category == '데이터파일') {
      debugPrint('✓ Updated keyword mapping successfully');
    } else {
      debugPrint('✗ Failed to update keyword mapping');
    }
  } catch (e) {
    debugPrint('✗ Error updating keyword mapping: $e');
  }

  // Test 8: Test remove mapping
  final removedConfig = config.removeKeywordMapping('report');
  if (removedConfig.keywordMappings.length == config.keywordMappings.length - 1) {
    debugPrint('✓ Removed keyword mapping successfully');
  } else {
    debugPrint('✗ Failed to remove keyword mapping');
  }

  debugPrint('\nAll tests completed!');
}
