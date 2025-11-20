import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/utils/keyword_mapping_error_handler.dart';

class EditKeywordDialog extends HookConsumerWidget {
  final KeywordMapping originalMapping;
  final List<String> categories;
  final List<KeywordMapping> existingMappings;

  const EditKeywordDialog({
    required this.originalMapping,
    required this.categories,
    required this.existingMappings,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternController = useTextEditingController(text: originalMapping.pattern);
    final categoryController = useTextEditingController();
    final testFileNameController = useTextEditingController();

    final selectedCategory = useState<String?>(
      categories.contains(originalMapping.category) ? originalMapping.category : null,
    );
    final isRegex = useState<bool>(originalMapping.isRegex);
    final caseSensitive = useState<bool>(originalMapping.caseSensitive);
    final patternError = useState<KeywordMappingException?>(null);
    final categoryError = useState<KeywordMappingException?>(null);
    final duplicateError = useState<KeywordMappingException?>(null);
    final testResult = useState<Map<String, dynamic>?>(null);
    final showHelp = useState<bool>(false);

    // Initialize category controller if not in dropdown
    useEffect(() {
      if (!categories.contains(originalMapping.category)) {
        categoryController.text = originalMapping.category;
      }
      return null;
    }, []);

    // Validation function
    void validateForm() {
      patternError.value = null;
      categoryError.value = null;
      duplicateError.value = null;

      final pattern = patternController.text.trim();
      final category = selectedCategory.value ?? categoryController.text.trim();

      // Create temporary mapping for validation
      final tempMapping = KeywordMapping(
        pattern: pattern,
        category: category,
        isRegex: isRegex.value,
        caseSensitive: caseSensitive.value,
      );

      // Validate using enhanced validation
      final validationErrors = tempMapping.validate();
      if (validationErrors.isNotEmpty) {
        final firstError = validationErrors.first;
        switch (firstError.type) {
          case KeywordMappingErrorType.emptyPattern:
          case KeywordMappingErrorType.invalidRegex:
          case KeywordMappingErrorType.patternTooLong:
          case KeywordMappingErrorType.patternTooComplex:
            patternError.value = firstError;
            break;
          case KeywordMappingErrorType.emptyCategory:
          case KeywordMappingErrorType.categoryTooLong:
            categoryError.value = firstError;
            break;
          default:
            patternError.value = firstError;
        }
        return;
      }

      // Check for duplicate patterns (excluding the original pattern)
      final isDuplicate = existingMappings.any(
        (mapping) =>
            mapping.pattern.toLowerCase() == pattern.toLowerCase() && mapping.pattern != originalMapping.pattern,
      );
      if (isDuplicate) {
        duplicateError.value = const KeywordMappingException(
          '이미 존재하는 패턴입니다.',
          KeywordMappingErrorType.duplicatePattern,
          userFriendlyMessage: '이미 같은 패턴의 규칙이 있습니다. 다른 패턴을 사용해주세요.',
        );
        return;
      }
    }

    // Test pattern function
    void testPattern() {
      final pattern = patternController.text.trim();
      final testFileName = testFileNameController.text.trim();

      if (pattern.isEmpty || testFileName.isEmpty) {
        testResult.value = {
          'matches': false,
          'error': '패턴과 테스트 파일명을 모두 입력해주세요.',
          'suggestion': '패턴과 파일명을 입력한 후 다시 시도해주세요.',
        };
        return;
      }

      final tempMapping = KeywordMapping(
        pattern: pattern,
        category: 'test',
        isRegex: isRegex.value,
        caseSensitive: caseSensitive.value,
      );

      // Use enhanced pattern testing
      final result = <String, dynamic>{'matches': false, 'error': null, 'suggestion': null};

      try {
        result['matches'] = tempMapping.testPattern(testFileName, throwOnError: true);
      } catch (e) {
        if (e is KeywordMappingException) {
          result['error'] = e.displayMessage;
          result['suggestion'] = e.suggestionMessage;
        } else {
          result['error'] = e.toString();
          result['suggestion'] = '패턴을 확인하고 다시 시도해주세요.';
        }
      }

      testResult.value = result;
    }

    // Check if form has changes
    bool hasChanges() {
      final pattern = patternController.text.trim();
      final category = selectedCategory.value ?? categoryController.text.trim();

      return pattern != originalMapping.pattern ||
          category != originalMapping.category ||
          isRegex.value != originalMapping.isRegex ||
          caseSensitive.value != originalMapping.caseSensitive;
    }

    // Listen to pattern changes for real-time validation
    useEffect(() {
      void listener() {
        if (patternController.text.isNotEmpty) {
          validateForm();
        }
      }

      patternController.addListener(listener);
      return () => patternController.removeListener(listener);
    }, [patternController]);

    return AlertDialog(
      title: const Text('키워드 규칙 편집'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pattern input
              TextField(
                controller: patternController,
                decoration: InputDecoration(
                  labelText: '패턴',
                  hintText: isRegex.value ? r'\d{4}.*report' : 'report',
                  errorText: (patternError.value ?? duplicateError.value)?.displayMessage,
                  suffixIcon: IconButton(
                    icon: Icon(showHelp.value ? Icons.help : Icons.help_outline),
                    onPressed: () => showHelp.value = !showHelp.value,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Pattern options
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('정규식 사용'),
                      subtitle: const Text('고급 패턴 매칭'),
                      value: isRegex.value,
                      onChanged: (value) {
                        isRegex.value = value ?? false;
                        validateForm();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('대소문자 구분'),
                      value: caseSensitive.value,
                      onChanged: (value) {
                        caseSensitive.value = value ?? false;
                        validateForm();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category selection
              Text('카테고리', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              if (categories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedCategory.value,
                  decoration: const InputDecoration(labelText: '기존 카테고리 선택', border: OutlineInputBorder()),
                  items:
                      categories.map((category) {
                        return DropdownMenuItem(value: category, child: Text(category));
                      }).toList(),
                  onChanged: (value) {
                    selectedCategory.value = value;
                    if (value != null) {
                      categoryController.clear();
                    }
                    validateForm();
                  },
                ),

                const SizedBox(height: 8),
                const Text('또는', textAlign: TextAlign.center),
                const SizedBox(height: 8),
              ],

              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: '새 카테고리 입력',
                  hintText: '보고서, 데이터, 백업 등',
                  errorText: categoryError.value?.displayMessage,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    selectedCategory.value = null;
                  }
                  validateForm();
                },
              ),

              const SizedBox(height: 16),

              // Pattern testing section
              ExpansionTile(
                title: const Text('패턴 테스트'),
                subtitle: const Text('패턴이 올바르게 작동하는지 확인'),
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: testFileNameController,
                    decoration: const InputDecoration(
                      labelText: '테스트 파일명',
                      hintText: '2024_annual_report.pdf',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: testPattern,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('테스트 실행'),
                        ),
                      ),
                    ],
                  ),
                  if (testResult.value != null) ...[
                    const SizedBox(height: 8),
                    KeywordMappingErrorHandler.buildPatternTestResult(
                      testFileNameController.text,
                      KeywordMapping(
                        pattern: patternController.text,
                        category: 'test',
                        isRegex: isRegex.value,
                        caseSensitive: caseSensitive.value,
                      ),
                      testResult.value!,
                    ),
                  ],
                ],
              ),

              // Help section
              if (showHelp.value) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '패턴 예시',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('단순 텍스트:'),
                      const Text('• report → "report"가 포함된 파일'),
                      const Text('• backup → "backup"이 포함된 파일'),
                      const SizedBox(height: 8),
                      const Text('정규식 패턴:'),
                      const Text(r'• \d{4}.*report → "2024_annual_report.pdf"'),
                      const Text(r'• backup_\w+_\d+ → "backup_db_20240101.sql"'),
                      const Text(r'• (IMG|DSC)_\d+ → "IMG_1234.jpg", "DSC_5678.jpg"'),
                      const Text(r'• .*\.(tmp|temp)$ → 임시 파일 확장자'),
                    ],
                  ),
                ),
              ],

              // Show changes indicator
              if (hasChanges()) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text('변경사항이 있습니다.'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
        TextButton(
          onPressed:
              hasChanges()
                  ? () {
                    validateForm();

                    if (patternError.value == null && categoryError.value == null && duplicateError.value == null) {
                      final pattern = patternController.text.trim();
                      final category = selectedCategory.value ?? categoryController.text.trim();

                      try {
                        final updatedMapping = originalMapping.copyWith(
                          pattern: pattern,
                          category: category,
                          isRegex: isRegex.value,
                          caseSensitive: caseSensitive.value,
                        );

                        // Final validation before returning
                        final finalErrors = updatedMapping.validate();
                        if (finalErrors.isNotEmpty) {
                          KeywordMappingErrorHandler.showErrorSnackBar(context, finalErrors.first);
                          return;
                        }

                        Navigator.of(context).pop(updatedMapping);
                      } catch (e) {
                        if (e is KeywordMappingException) {
                          KeywordMappingErrorHandler.showErrorSnackBar(context, e);
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')));
                        }
                      }
                    }
                  }
                  : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
