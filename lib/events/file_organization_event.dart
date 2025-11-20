import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/services/file_organization_service.dart';
import 'package:macos_file_manager/services/file_system_service.dart';
import 'package:macos_file_manager/widgets/dialogs/file_organization_completion_dialog.dart';
import 'package:macos_file_manager/widgets/dialogs/file_organization_detailed_report_dialog.dart';
import 'package:macos_file_manager/widgets/dialogs/file_organization_preview_dialog.dart';
import 'package:path/path.dart' as path;

mixin class FileOrganizationEvent {
  Future<void> organizeDirectoryWithAI(WidgetRef ref, BuildContext context) async {
    final fileSystemItems = ref.read(fileSystemItemListProvider);
    final currentDir = ref.read(currentDirectoryProvider);

    if (!context.mounted) return;

    if (fileSystemItems.isEmpty) {
      _showSnackBar(context, AppStrings.noFilesToOrganize);
      return;
    }

    _showLoadingDialog(context, AppStrings.aiAnalyzingFiles);

    try {
      final organizationResults = await _analyzeFilesWithDetails(ref, fileSystemItems);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // 분석 로딩 다이얼로그 닫기

      if (organizationResults.isEmpty) {
        _showSnackBar(context, AppStrings.aiFailedToClassify);
        return;
      }

      final confirmed = await _showEnhancedOrganizationPreview(context, organizationResults);
      if (confirmed != true) return;

      final summary = await _executeEnhancedFileOrganization(context, currentDir, organizationResults);

      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);

      if (!context.mounted) return;

      await _showEnhancedCompletionDialogWithUndo(context, ref, currentDir, summary);
    } catch (e) {
      developer.log('Error during file organization: $e');
      _handleOrganizationError(context, e);
    }
  }

  /// 완료 다이얼로그를 표시하고 되돌리기 기능을 처리
  Future<void> _showEnhancedCompletionDialogWithUndo(
    BuildContext context,
    WidgetRef ref,
    String currentDir,
    FileOrganizationSummary summary,
  ) async {
    final action = await _showEnhancedCompletionDialog(context, ref, currentDir, summary);

    if (action == 'undo') {
      await _undoEnhancedFileOrganization(context, ref, currentDir, summary);
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Text(message)]),
          ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _handleOrganizationError(BuildContext context, dynamic error) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // 열려있는 다이얼로그 닫기
    }
    _showSnackBar(context, '${AppStrings.errorDuringOrganization} $error');
  }

  /// 상세한 파일 분석 (키워드 매칭 정보 포함)
  Future<List<FileOrganizationResult>> _analyzeFilesWithDetails(
    WidgetRef ref,
    List<FileSystemItem> fileSystemItems,
  ) async {
    final fileService = ref.read(fileOrganizationServiceProvider);
    final List<FileOrganizationResult> results = [];

    for (final item in fileSystemItems) {
      if (item.type == FileSystemItemType.file) {
        final snippet = await _readFileSnippet(item);
        final result = fileService.classifyFileWithDetails(item.path, item.name, snippet);
        results.add(result);
      }
    }

    return results;
  }

  Future<String> _readFileSnippet(FileSystemItem item) async {
    try {
      // 바이너리 파일 확장자 목록 (텍스트로 읽을 수 없는 파일들)
      const binaryExtensions = {
        // 이미지
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp', 'ico', 'svg',
        // 문서
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'hwp',
        // 압축
        'zip', 'rar', '7z', 'tar', 'gz', 'bz2',
        // 실행파일
        'exe', 'dmg', 'pkg', 'deb', 'rpm',
        // 미디어
        'mp3', 'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'wav', 'flac',
        // 기타 바이너리
        'bin', 'dat', 'db', 'sqlite', 'sqlite3',
      };

      final extension = item.fileExtension.toLowerCase().replaceFirst('.', '');

      // 바이너리 파일은 빈 문자열 반환
      if (binaryExtensions.contains(extension)) {
        return "";
      }

      final file = File(item.path);
      String snippet = await file.readAsString();

      if (snippet.length > 500) {
        snippet = snippet.substring(0, 500);
      }

      return snippet;
    } catch (e) {
      developer.log('Failed to read file snippet for ${item.name}: $e');
      return "";
    }
  }

  /// 향상된 파일 정리 미리보기 다이얼로그
  Future<bool?> _showEnhancedOrganizationPreview(BuildContext context, List<FileOrganizationResult> results) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return FileOrganizationPreviewDialog(results: results);
      },
    );
  }

  /// 향상된 파일 정리 실행 (상세 결과 포함)
  Future<FileOrganizationSummary> _executeEnhancedFileOrganization(
    BuildContext context,
    String currentDir,
    List<FileOrganizationResult> results,
  ) async {
    _showLoadingDialog(context, AppStrings.movingFiles);

    final List<FileOrganizationResult> processedResults = [];

    try {
      for (final result in results) {
        final sourcePath = result.filePath;
        final category = result.category;
        final targetDir = path.join(currentDir, category);

        // 대상 폴더 생성
        await Directory(targetDir).create(recursive: true);

        final originalFileName = path.basename(sourcePath);
        final safeFileName = _getSafeFileName(originalFileName, targetDir);
        final destinationPath = path.join(targetDir, safeFileName);

        // 파일 이동 실행
        await File(sourcePath).rename(destinationPath);

        // 처리된 결과에 새 경로로 업데이트하여 추가
        final processedResult = FileOrganizationResult(
          filePath: destinationPath,
          fileName: safeFileName, // 안전한 파일명 사용
          category: result.category,
          method: result.method,
          matchedPattern: result.matchedPattern,
          matchedExtension: result.matchedExtension,
        );
        processedResults.add(processedResult);

        // 로그 출력
        developer.log('Moved file: ${result.fileName} -> $safeFileName (${result.category})');
      }

      return FileOrganizationSummary(results: processedResults, timestamp: DateTime.now());
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// 안전한 파일명 생성 (경로 길이 제한 고려)
  String _getSafeFileName(String originalFileName, String targetDir) {
    const maxPathLength = 250; // macOS 경로 길이 제한보다 여유있게 설정
    const maxFileNameLength = 200; // 파일명 자체의 최대 길이

    // 전체 경로 길이 계산
    final potentialPath = path.join(targetDir, originalFileName);

    // 경로가 너무 길지 않으면 원본 파일명 사용
    if (potentialPath.length <= maxPathLength && originalFileName.length <= maxFileNameLength) {
      return originalFileName;
    }

    // 파일명이 너무 길면 단축
    final extension = path.extension(originalFileName);
    final nameWithoutExtension = path.basenameWithoutExtension(originalFileName);

    // 확장자를 제외한 이름 부분의 최대 길이 계산
    final maxNameLength = maxFileNameLength - extension.length - 10; // 여유분 10자

    if (nameWithoutExtension.length > maxNameLength) {
      // URL 디코딩 시도
      String decodedName = nameWithoutExtension;
      try {
        decodedName = Uri.decodeComponent(nameWithoutExtension);
      } catch (e) {
        // 디코딩 실패시 원본 사용
      }

      // 파일명 단축
      final truncatedName =
          decodedName.length > maxNameLength ? decodedName.substring(0, maxNameLength.toInt()) : decodedName;

      final safeFileName = '$truncatedName$extension';

      // 중복 파일명 처리
      return _getUniqueFileName(safeFileName, targetDir);
    }

    return originalFileName;
  }

  /// 중복되지 않는 고유한 파일명 생성
  String _getUniqueFileName(String fileName, String targetDir) {
    final extension = path.extension(fileName);
    final nameWithoutExtension = path.basenameWithoutExtension(fileName);

    String uniqueFileName = fileName;
    int counter = 1;

    while (File(path.join(targetDir, uniqueFileName)).existsSync()) {
      uniqueFileName = '${nameWithoutExtension}_$counter$extension';
      counter++;
    }

    return uniqueFileName;
  }

  /// 향상된 완료 다이얼로그 (상세 결과 표시)
  Future<String?> _showEnhancedCompletionDialog(
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
      return await _showEnhancedCompletionDialog(context, ref, currentDir, summary);
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

  /// 향상된 파일 정리 되돌리기
  Future<void> _undoEnhancedFileOrganization(
    BuildContext context,
    WidgetRef ref,
    String currentDir,
    FileOrganizationSummary summary,
  ) async {
    if (!context.mounted) return;

    _showLoadingDialog(context, AppStrings.undoingFiles);

    try {
      for (final result in summary.results) {
        // 현재 경로에서 원래 경로로 되돌리기
        final currentPath = result.filePath;
        final originalPath = path.join(currentDir, result.fileName);

        if (File(currentPath).existsSync()) {
          await File(currentPath).rename(originalPath);
          developer.log('Undid file move: ${result.fileName} from ${result.category} back to root');
        }
      }

      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
      _showSnackBar(context, AppStrings.fileOrganizationUndone);

      // 되돌리기 로그 출력
      developer.log('File organization undone. ${summary.totalCount} files restored to original locations.');
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // 되돌리기 로딩 다이얼로그 닫기
      }
    }
  }
}
