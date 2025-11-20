import 'package:flutter/material.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';

/// 파일 정리 상세 보고서 다이얼로그
class FileOrganizationDetailedReportDialog extends StatelessWidget {
  final FileOrganizationSummary summary;

  const FileOrganizationDetailedReportDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.fileOrganizationDetailedReport),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Text(summary.generateDetailedReport(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.close))],
    );
  }
}
