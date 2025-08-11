import 'package:flutter/material.dart';

import 'lib/model/keyword_mapping.dart';

void main() {
  // Test basic functionality
  final mapping = KeywordMapping(pattern: 'report', category: '보고서', isRegex: false, caseSensitive: false, priority: 1);

  debugPrint('Original mapping: $mapping');

  // Test JSON serialization
  final json = mapping.toJson();
  debugPrint('JSON: $json');

  // Test JSON deserialization
  final fromJson = KeywordMapping.fromJson(json);
  debugPrint('From JSON: $fromJson');

  // Test equality
  debugPrint('Equal: ${mapping == fromJson}');

  // Test copyWith
  final copied = mapping.copyWith(priority: 2);
  debugPrint('Copied with priority 2: $copied');

  // Test validation
  final validMapping = KeywordMapping(pattern: 'test', category: 'Test');
  debugPrint('Valid mapping errors: ${validMapping.validate()}');

  final invalidMapping = KeywordMapping(pattern: '', category: '');
  debugPrint('Invalid mapping errors: ${invalidMapping.validate()}');

  // Test regex validation
  final regexMapping = KeywordMapping(pattern: r'\d{4}.*report', category: '연도별 보고서', isRegex: true);
  debugPrint('Regex mapping valid: ${regexMapping.isValidRegexPattern()}');

  final invalidRegexMapping = KeywordMapping(pattern: '[invalid regex', category: 'Test', isRegex: true);
  debugPrint('Invalid regex mapping valid: ${invalidRegexMapping.isValidRegexPattern()}');
}
