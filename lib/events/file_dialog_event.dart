import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';
import 'package:macos_file_manager/widgets/dialogs/file_organization_completion_dialog.dart';
import 'package:macos_file_manager/widgets/dialogs/file_organization_detailed_report_dialog.dart';
import 'package:macos_file_manager/widgets/dialogs/file_organization_preview_dialog.dart';

/// 파일 정리 관련 다이얼로그 이벤트를 처리하는 mixin
mixin class FileDialogEvent {
  /// 향상된 파일 정리 미리보기 다이얼로그
  Future<bool?> showEnhancedOrganizationPreview(BuildContext context, List<FileOrganizationResult> results) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return FileOrganizationPreviewDialog(results: results);
      },
    );
  }

  /// 향상된 완료 다이얼로그 (상세 결과 표시)
  Future<String?> showEnhancedCompletionDialog(
    BuildContext context,
    WidgetRef ref,
    String currentDir,
    FileOrganizationSummary summary,
  ) async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FileOrganizationCompletionDialog(summary: summary);
      },
    );

    if (action == 'details') {
      await _showDetailedReport(context, summary);
      // 상세 보기 후 다시 완료 다이얼로그 표시
      return await showEnhancedCompletionDialog(context, ref, currentDir, summary);
    } else if (action == 'keep') {
      _showSnackBar(context, AppStrings.fileOrganizationKept);
      // 상세 로그 출력
      developer.log('File organization summary:\n${summary.generateDetailedReport()}');
    }

    return action;
  }

  /// 상세 보고서 다이얼로그
  Future<void> _showDetailedReport(BuildContext context, FileOrganizationSummary summary) async {
    await showDialog(
      context: context,
      builder: (context) {
        return FileOrganizationDetailedReportDialog(summary: summary);
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
