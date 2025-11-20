import 'package:flutter/material.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';

/// 파일 정리 완료 다이얼로그
class FileOrganizationCompletionDialog extends StatelessWidget {
  final FileOrganizationSummary summary;

  const FileOrganizationCompletionDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.fileOrganizationComplete),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary.generateSummaryMessage()),
              const SizedBox(height: 16),

              // 키워드 기반 결과 표시
              if (summary.hasKeywordBasedResults) ...[
                Text(
                  '📝 ${AppStrings.keywordBasedOrganization} (${summary.keywordBasedCount}개)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...summary.keywordMatchCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• ${AppStrings.patternMatch} "${entry.key}": ${entry.value}개'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 확장자 기반 결과 표시
              if (summary.hasExtensionBasedResults) ...[
                Text(
                  '📄 ${AppStrings.extensionBasedOrganization} (${summary.extensionBasedCount}개)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...summary.extensionMatchCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• ${AppStrings.extensionMatch} ".${entry.key}": ${entry.value}개'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 기타 결과 표시
              if (summary.otherCount > 0) ...[
                Text(
                  '📋 ${AppStrings.otherOrganization} (${summary.otherCount}개)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],

              // 카테고리별 요약
              Text(
                '📊 ${AppStrings.categorySummary}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.categoryCounts.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text('• ${entry.key}: ${entry.value}개'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop('details'), child: const Text(AppStrings.detailsView)),
        TextButton(onPressed: () => Navigator.of(context).pop('undo'), child: const Text(AppStrings.undo)),
        TextButton(onPressed: () => Navigator.of(context).pop('keep'), child: const Text(AppStrings.keep)),
      ],
    );
  }
}
