import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';
import 'package:macos_file_manager/services/file_system_service.dart';
import 'package:path/path.dart' as path;

/// 파일 정리 실행 관련 이벤트를 처리하는 mixin
mixin class FileExecutionEvent {
  /// 향상된 파일 정리 실행 (상세 결과 포함)
  Future<FileOrganizationSummary> executeEnhancedFileOrganization(
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

  /// 향상된 파일 정리 되돌리기
  Future<void> undoEnhancedFileOrganization(
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
      final truncatedName = decodedName.length > maxNameLength ? decodedName.substring(0, maxNameLength) : decodedName;

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
}
