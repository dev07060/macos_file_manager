import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/utils/keyword_mapping_error_handler.dart';

class AddKeywordDialog extends HookConsumerWidget {
  final List<String> categories;
  final List<KeywordMapping> existingMappings;

  const AddKeywordDialog({required this.categories, required this.existingMappings, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternController = useTextEditingController();
    final categoryController = useTextEditingController();
    final testFileNameController = useTextEditingController();

    final selectedCategory = useState<String?>(null);
    final isRegex = useState<bool>(false);
    final caseSensitive = useState<bool>(false);
    final patternError = useState<KeywordMappingException?>(null);
    final categoryError = useState<KeywordMappingException?>(null);
    final duplicateError = useState<KeywordMappingException?>(null);
    final testResult = useState<Map<String, dynamic>?>(null);
    final showHelp = useState<bool>(false);

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

      // Check for duplicate patterns
      final isDuplicate = existingMappings.any((mapping) => mapping.pattern.toLowerCase() == pattern.toLowerCase());
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
          'error': AppStrings.patternAndTestFileRequired,
          'suggestion': AppStrings.patternAndFileNameRequired,
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
          result['suggestion'] = AppStrings.checkPatternAndRetry;
        }
      }

      testResult.value = result;
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
      title: const Text(AppStrings.addKeywordRule),
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
                  labelText: AppStrings.pattern,
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
                      title: const Text(AppStrings.useRegex),
                      subtitle: const Text(AppStrings.advancedPatternMatching),
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
                      title: const Text(AppStrings.caseSensitiveMatching),
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
              Text(AppStrings.category, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              if (categories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedCategory.value,
                  decoration: const InputDecoration(
                    labelText: AppStrings.selectExistingCategory,
                    border: OutlineInputBorder(),
                  ),
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
                const Text(AppStrings.or, textAlign: TextAlign.center),
                const SizedBox(height: 8),
              ],

              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: AppStrings.enterNewCategory,
                  hintText: AppStrings.newCategoryHint,
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
                title: const Text(AppStrings.patternTestSection),
                subtitle: const Text(AppStrings.patternTestDescription),
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: testFileNameController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.testFileNameLabel,
                      hintText: AppStrings.testFileNameHint,
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
                          label: const Text(AppStrings.runTest),
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
                        AppStrings.patternExamples,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(AppStrings.simpleText),
                      const Text('• report → "report"가 포함된 파일'),
                      const Text('• backup → "backup"이 포함된 파일'),
                      const SizedBox(height: 8),
                      const Text(AppStrings.regexPatterns),
                      const Text(r'• \d{4}.*report → "2024_annual_report.pdf"'),
                      const Text(r'• backup_\w+_\d+ → "backup_db_20240101.sql"'),
                      const Text(r'• (IMG|DSC)_\d+ → "IMG_1234.jpg", "DSC_5678.jpg"'),
                      const Text(r'• .*\.(tmp|temp)$ → 임시 파일 확장자'),
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
          onPressed: () {
            validateForm();

            if (patternError.value == null && categoryError.value == null && duplicateError.value == null) {
              final pattern = patternController.text.trim();
              final category = selectedCategory.value ?? categoryController.text.trim();

              try {
                final keywordMapping = KeywordMapping(
                  pattern: pattern,
                  category: category,
                  isRegex: isRegex.value,
                  caseSensitive: caseSensitive.value,
                  priority: existingMappings.length, // Set priority as next in sequence
                  isCustom: true,
                );

                // Final validation before returning
                final finalErrors = keywordMapping.validate();
                if (finalErrors.isNotEmpty) {
                  KeywordMappingErrorHandler.showErrorSnackBar(context, finalErrors.first);
                  return;
                }

                Navigator.of(context).pop(keywordMapping);
              } catch (e) {
                if (e is KeywordMappingException) {
                  KeywordMappingErrorHandler.showErrorSnackBar(context, e);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('${AppStrings.errorOccurred} ${e.toString()}')));
                }
              }
            }
          },
          child: const Text(AppStrings.add),
        ),
      ],
    );
  }
}
