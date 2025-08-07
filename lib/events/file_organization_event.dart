import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/file_constants.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/services/file_organization_service.dart';
import 'package:macos_file_manager/services/file_system_service.dart';
import 'package:path/path.dart' as path;

mixin class FileOrganizationEvent {
  Future<void> organizeDirectoryWithAI(WidgetRef ref, BuildContext context) async {
    final fileSystemItems = ref.read(fileSystemItemListProvider);
    final currentDir = ref.read(currentDirectoryProvider);

    if (!context.mounted) return;

    if (fileSystemItems.isEmpty) {
      _showSnackBar(context, '정리할 파일이 없습니다.');
      return;
    }

    _showLoadingDialog(context, 'AI가 파일을 분석 중입니다...');

    try {
      final fileToCategoryMap = await _analyzeFiles(ref, fileSystemItems);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // 분석 로딩 다이얼로그 닫기

      if (fileToCategoryMap.isEmpty) {
        _showSnackBar(context, 'AI가 분류할 파일을 찾지 못했습니다.');
        return;
      }

      final confirmed = await _showOrganizationPreview(context, fileToCategoryMap);
      if (confirmed != true) return;

      final movedFilesLog = await _executeFileOrganization(context, currentDir, fileToCategoryMap);

      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);

      if (!context.mounted) return;

      await _showCompletionDialog(context, ref, currentDir, movedFilesLog);
    } catch (e) {
      developer.log('Error during file organization: $e');
      _handleOrganizationError(context, e);
    }
  }

  Future<Map<String, String>> _analyzeFiles(WidgetRef ref, List<FileSystemItem> fileSystemItems) async {
    final fileService = ref.read(fileOrganizationServiceProvider);
    final Map<String, String> fileToCategoryMap = {};

    for (final item in fileSystemItems) {
      if (item.type == FileSystemItemType.file) {
        final snippet = await _readFileSnippet(item);
        final category = fileService.classifyFile(item.name, snippet);
        fileToCategoryMap[item.path] = category;
      }
    }

    return fileToCategoryMap;
  }

  Future<String> _readFileSnippet(FileSystemItem item) async {
    try {
      if (FileConstants.imageExtensions.contains(item.fileExtension.toLowerCase())) {
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

  Future<bool?> _showOrganizationPreview(BuildContext context, Map<String, String> fileToCategoryMap) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('파일 정리 제안'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(child: _buildCategoryPreview(context, fileToCategoryMap)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('확인')),
          ],
        );
      },
    );
  }

  Widget _buildCategoryPreview(BuildContext context, Map<String, String> fileToCategoryMap) {
    final Map<String, List<String>> categoryToFileList = {};

    fileToCategoryMap.forEach((filePath, category) {
      categoryToFileList.putIfAbsent(category, () => []).add(filePath);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children:
          categoryToFileList.entries.map((categoryEntry) {
            final categoryName = categoryEntry.key;
            final filesInCategory = categoryEntry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                  child: Text(
                    '"$categoryName" 폴더 (${filesInCategory.length}개)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ...filesInCategory.map((filePath) => ListTile(title: Text(path.basename(filePath)), dense: true)),
              ],
            );
          }).toList(),
    );
  }

  Future<List<Map<String, String>>> _executeFileOrganization(
    BuildContext context,
    String currentDir,
    Map<String, String> fileToCategoryMap,
  ) async {
    _showLoadingDialog(context, '파일을 이동 중입니다...');

    final List<Map<String, String>> movedFilesLog = [];

    try {
      for (final entry in fileToCategoryMap.entries) {
        final sourcePath = entry.key;
        final category = entry.value;
        final targetDir = path.join(currentDir, category);

        // 대상 폴더 생성
        await Directory(targetDir).create(recursive: true);

        final fileName = path.basename(sourcePath);
        final destinationPath = path.join(targetDir, fileName);

        // 파일 이동 로그 기록
        movedFilesLog.add({'originalPath': sourcePath, 'newPath': destinationPath});

        // 파일 이동 실행
        await File(sourcePath).rename(destinationPath);
      }

      return movedFilesLog;
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showCompletionDialog(
    BuildContext context,
    WidgetRef ref,
    String currentDir,
    List<Map<String, String>> movedFilesLog,
  ) async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('파일 정리 완료'),
          content: const Text('파일 정리가 완료되었습니다.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop('undo'), child: const Text('되돌리기')),
            TextButton(onPressed: () => Navigator.of(context).pop('keep'), child: const Text('유지하기')),
          ],
        );
      },
    );

    if (action == 'undo') {
      await _undoFileOrganization(context, ref, currentDir, movedFilesLog);
    } else if (action == 'keep') {
      _showSnackBar(context, '파일 정리가 유지됩니다.');
    }
  }

  /// 파일 정리를 되돌리기
  Future<void> _undoFileOrganization(
    BuildContext context,
    WidgetRef ref,
    String currentDir,
    List<Map<String, String>> movedFilesLog,
  ) async {
    if (!context.mounted) return;

    _showLoadingDialog(context, '파일을 되돌리는 중입니다...');

    try {
      for (final logEntry in movedFilesLog) {
        final originalPath = logEntry['originalPath']!;
        final newPath = logEntry['newPath']!;
        await File(newPath).rename(originalPath);
      }

      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
      _showSnackBar(context, '파일 위치를 되돌렸습니다.');
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // 되돌리기 로딩 다이얼로그 닫기
      }
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
    _showSnackBar(context, '파일 정리 중 오류 발생: $error');
  }
}
