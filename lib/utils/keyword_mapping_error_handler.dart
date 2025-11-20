import 'package:flutter/material.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';

/// 키워드 매핑 오류 처리 유틸리티 클래스
class KeywordMappingErrorHandler {
  /// 오류를 사용자 친화적인 메시지로 변환
  static String getDisplayMessage(dynamic error) {
    if (error is KeywordMappingException) {
      return error.displayMessage;
    } else if (error is Exception) {
      return '예상치 못한 오류가 발생했습니다: ${error.toString()}';
    } else {
      return error.toString();
    }
  }

  /// 오류 타입에 따른 아이콘 반환
  static IconData getErrorIcon(KeywordMappingErrorType errorType) {
    switch (errorType) {
      case KeywordMappingErrorType.duplicatePattern:
        return Icons.content_copy;
      case KeywordMappingErrorType.emptyPattern:
        return Icons.text_fields;
      case KeywordMappingErrorType.invalidRegex:
        return Icons.code_off;
      case KeywordMappingErrorType.emptyCategory:
        return Icons.folder_off;
      case KeywordMappingErrorType.invalidPriority:
        return Icons.priority_high;
      case KeywordMappingErrorType.runtimeRegexError:
        return Icons.error_outline;
      case KeywordMappingErrorType.patternTooComplex:
        return Icons.error_outline;
      case KeywordMappingErrorType.categoryTooLong:
        return Icons.text_increase;
      case KeywordMappingErrorType.patternTooLong:
        return Icons.text_increase;
    }
  }

  /// 오류 타입에 따른 색상 반환
  static Color getErrorColor(KeywordMappingErrorType errorType) {
    switch (errorType) {
      case KeywordMappingErrorType.duplicatePattern:
        return Colors.orange;
      case KeywordMappingErrorType.emptyPattern:
      case KeywordMappingErrorType.emptyCategory:
        return Colors.blue;
      case KeywordMappingErrorType.invalidRegex:
      case KeywordMappingErrorType.runtimeRegexError:
      case KeywordMappingErrorType.patternTooComplex:
        return Colors.red;
      case KeywordMappingErrorType.invalidPriority:
        return Colors.purple;
      case KeywordMappingErrorType.categoryTooLong:
      case KeywordMappingErrorType.patternTooLong:
        return Colors.amber;
    }
  }

  /// 오류 다이얼로그 표시
  static Future<void> showErrorDialog(
    BuildContext context,
    KeywordMappingException error, {
    String? title,
    List<Widget>? actions,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(getErrorIcon(error.type), color: getErrorColor(error.type)),
              const SizedBox(width: 8),
              Text(title ?? '오류'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.displayMessage),
              const SizedBox(height: 16),
              Text('해결 방법:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error.suggestionMessage),
              if (error.technicalDetails != null) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('기술적 세부사항'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        error.technicalDetails!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: actions ?? [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
        );
      },
    );
  }

  /// 오류 스낵바 표시
  static void showErrorSnackBar(
    BuildContext context,
    KeywordMappingException error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(getErrorIcon(error.type), color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(error.displayMessage)),
          ],
        ),
        backgroundColor: getErrorColor(error.type),
        duration: duration,
        action: action,
      ),
    );
  }

  /// 여러 오류를 요약하여 표시
  static Widget buildErrorSummary(List<KeywordMappingException> errors, {int maxDisplayErrors = 3}) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayErrors = errors.take(maxDisplayErrors).toList();
    final remainingCount = errors.length - displayErrors.length;

    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '${errors.length}개의 오류가 발견되었습니다',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...displayErrors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(getErrorIcon(error.type), size: 16, color: getErrorColor(error.type)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error.displayMessage)),
                  ],
                ),
              ),
            ),
            if (remainingCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '그 외 $remainingCount개의 오류가 더 있습니다.',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 오류 복구 제안 위젯
  static Widget buildRecoveryActions(
    KeywordMappingException error, {
    required VoidCallback onRetry,
    VoidCallback? onSkip,
    VoidCallback? onEdit,
  }) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('복구 옵션', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Text(error.suggestionMessage),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
                if (onEdit != null)
                  OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit), label: const Text('수정')),
                if (onSkip != null)
                  TextButton.icon(onPressed: onSkip, icon: const Icon(Icons.skip_next), label: const Text('건너뛰기')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 유효성 검사 결과 위젯
  static Widget buildValidationResult(List<KeywordMappingException> errors, {String? successMessage}) {
    if (errors.isEmpty) {
      return Card(
        color: Colors.green.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                successMessage ?? '모든 검사를 통과했습니다.',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else {
      return buildErrorSummary(errors);
    }
  }

  /// 패턴 테스트 결과 위젯
  static Widget buildPatternTestResult(String fileName, KeywordMapping mapping, Map<String, dynamic> testResult) {
    final matches = testResult['matches'] as bool;
    final error = testResult['error'] as String?;
    final suggestion = testResult['suggestion'] as String?;

    if (error != null) {
      return Card(
        color: Colors.red.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('테스트 실패', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              Text('파일명: $fileName'),
              Text('패턴: ${mapping.pattern}'),
              Text('오류: $error'),
              if (suggestion != null) ...[
                const SizedBox(height: 8),
                Text('제안: $suggestion', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      );
    } else {
      final color = matches ? Colors.green : Colors.orange;
      final icon = matches ? Icons.check_circle : Icons.cancel;
      final message = matches ? '매칭됨' : '매칭되지 않음';

      return Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    Text('파일명: $fileName'),
                    Text('패턴: ${mapping.pattern}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
