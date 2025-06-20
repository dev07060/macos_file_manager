import 'dart:developer' as developer;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/file_constants.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/services/file_system_service.dart';
import 'package:macos_file_manager/services/vertex_ai_service.dart';
import 'package:path/path.dart' as path;

mixin class FileOperationEvent {
  Future<void> organizeDirectoryWithAI(WidgetRef ref, BuildContext context) async {
    final fileSystemItems = ref.read(fileSystemItemListProvider);
    final currentDir = ref.read(currentDirectoryProvider);

    if (!context.mounted) return;

    if (fileSystemItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('정리할 파일이 없습니다.')));
      return;
    }

    // AI 분석 중 로딩 다이얼로그 표시
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('AI가 파일을 분석 중입니다...')]),
          ),
    );

    // 되돌리기를 위한 파일 이동 기록
    final List<Map<String, String>> movedFilesLog = [];

    try {
      // vertexAIServiceProvider가 FutureProvider로 변경되었으므로, .future를 await하여 서비스 인스턴스를 안전하게 가져옵니다.
      final aiService = await ref.read(vertexAIServiceProvider.future);

      // 3. 파일 분류 작업
      final Map<String, String> fileToCategoryMap = {};
      for (final item in fileSystemItems) {
        if (item.type == FileSystemItemType.file) {
          String snippet = "";
          // 텍스트 기반 파일이면 내용 일부를 읽음 (비용 절약)
          try {
            if (!FileConstants.imageExtensions.contains(item.fileExtension.toLowerCase())) {
              final file = File(item.path);
              snippet = await file.readAsString();
              if (snippet.length > 500) {
                snippet = snippet.substring(0, 500);
              }
            }
          } catch (e) {
            developer.log('Failed to read file snippet for ${item.name}: $e');
          }

          final category = await aiService.classifyFile(item.name, snippet);
          if (category != null) {
            fileToCategoryMap[item.path] = category;
          }
        }
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // AI 분석 중 로딩 다이얼로그 닫기

      if (fileToCategoryMap.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI가 분류할 파일을 찾지 못했습니다.')));
        }
        return;
      }

      // 4. 사용자에게 확인받기
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('AI 파일 정리 제안'),
            content: SizedBox(
              // 다이얼로그 내용의 최대 높이 제한을 위해 SizedBox 사용
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.5, // 화면 높이의 50%로 제한
              child: SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    // Builder를 사용하여 올바른 context에서 MediaQuery 사용
                    // 카테고리별 파일 목록 생성
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ...filesInCategory.map(
                                  (filePath) => ListTile(title: Text(path.basename(filePath)), dense: true),
                                ),
                              ],
                            );
                          }).toList(),
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('확인')),
            ],
          );
        },
      );

      // 5. 파일 이동 실행
      if (confirmed == true) {
        // 파일 이동 중 로딩 다이얼로그 표시
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('파일을 이동 중입니다...')]),
              ),
        );

        try {
          for (final entry in fileToCategoryMap.entries) {
            final sourcePath = entry.key;
            final category = entry.value;
            final targetDir = path.join(currentDir, category);

            // 대상 폴더가 없으면 생성
            await Directory(targetDir).create(recursive: true);

            final fileName = path.basename(sourcePath);
            final destinationPath = path.join(targetDir, fileName);

            movedFilesLog.add({'originalPath': sourcePath, 'newPath': destinationPath});
            await File(sourcePath).rename(destinationPath);
          }
        } finally {
          if (context.mounted) {
            Navigator.of(context).pop(); // 파일 이동 중 로딩 다이얼로그 닫기
          }
        }

        await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
        if (!context.mounted) return;

        // 파일 정리 완료 후 되돌리기/유지하기 팝업 표시
        // ignore: use_build_context_synchronously
        final String? action = await showDialog<String>(
          context: context,
          barrierDismissible: false, // 사용자가 선택하도록 강제
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
          if (!context.mounted) return;
          // 되돌리기 중 로딩 다이얼로그 표시
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const AlertDialog(
                  content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('파일을 되돌리는 중입니다...')]),
                ),
          );
          try {
            for (final logEntry in movedFilesLog) {
              final originalPath = logEntry['originalPath']!;
              final newPath = logEntry['newPath']!;
              // 원래 경로의 부모 디렉토리가 존재하는지 확인 (일반적으로 rename은 신경쓰지 않지만, 만약을 위해)
              // final originalParentDir = Directory(path.dirname(originalPath));
              // if (!await originalParentDir.exists()) {
              //   await originalParentDir.create(recursive: true);
              // }
              await File(newPath).rename(originalPath);
            }
          } finally {
            if (context.mounted) {
              Navigator.of(context).pop(); // 되돌리기 중 로딩 다이얼로그 닫기
            }
          }
          await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파일 위치를 되돌렸습니다.')));
        } else if (action == 'keep') {
          // 파일 목록은 이미 새로고침됨
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파일 정리가 유지됩니다.')));
          }
        }
      }
    } catch (e) {
      developer.log('Error during AI file organization: $e');
      // AI 분석 중 로딩 다이얼로그가 아직 떠있을 수 있으므로, 여기서 닫아줍니다.
      // Navigator.canPop()으로 현재 최상단 다이얼로그가 AI 분석 다이얼로그인지 확인하는 더 안전한 방법이 필요할 수 있으나,
      // 현재 흐름상 AI 분석 다이얼로그 이후 다른 다이얼로그가 뜨기 전에 에러가 나면 이 catch로 올 가능성이 높습니다.
      if (context.mounted && Navigator.of(context).canPop()) {
        // AI 분석 다이얼로그 닫기 시도
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI 파일 정리 중 오류 발생: $e')));
      }
    }
  }

  /// Delete selected items
  Future<void> deleteSelectedItems(WidgetRef ref, BuildContext context) async {
    final service = ref.read(fileSystemServiceProvider);

    final selectedCount = service.getSelectedItemsCount();

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $selectedCount selected files?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await service.deleteSelectedItems();

      // Refresh the directory
      final currentDir = service.getCurrentDirectory();
      await service.loadDirectory(currentDir);

      // Clear the selection
      service.clearSelections();
    }
  }

  /// Compress selected items
  Future<void> compressSelectedItems(WidgetRef ref, BuildContext context) async {
    final currentDir = ref.read(fileSystemServiceProvider).getCurrentDirectory();
    final selectedItems = ref.read(fileSystemServiceProvider).getSelectedItems();

    if (selectedItems.isEmpty) return;

    // Default archive name based on the first selected item
    final firstItemName = path.basenameWithoutExtension(selectedItems.first.name);
    String archiveName = firstItemName;

    // Show dialog to set archive name
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: '$archiveName.zip');

        return AlertDialog(
          title: const Text('Create Archive'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'archive.zip', labelText: 'Archive File Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'fileName': controller.text});
              },
              child: const Text('Compress'),
            ),
          ],
        );
      },
    );

    if (result == null) return; // User canceled

    final zipFileName = result['fileName'];
    final zipFilePath = path.join(currentDir, zipFileName);

    // Check if a file with this name already exists
    if (File(zipFilePath).existsSync()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('File Already Exists'),
            content: Text('The file $zipFileName already exists. Do you want to overwrite it?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Overwrite')),
            ],
          );
        },
      );

      if (confirmed != true) return; // User canceled overwrite
    }

    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(width: 20),
              const Text('Compressing...'),
            ],
          ),
        );
      },
    );

    try {
      // Create archive
      final archive = Archive();

      // Add selected items to archive
      for (final item in selectedItems) {
        if (item.type == FileSystemItemType.file) {
          // Add file to archive
          final file = File(item.path);
          final bytes = await file.readAsBytes();

          // Use relative path from current directory
          String archivePath = path.basename(item.path);
          archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
        } else if (item.type == FileSystemItemType.directory) {
          // Add directory and its contents recursively
          await _addDirectoryToArchive(archive, item.path, path.basename(item.path));
        }
      }

      // Encode the archive to zip
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        // Write zip to file
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(zipData);
      }

      // Close progress dialog
      Navigator.of(context).pop();

      // Reload the directory to show the new zip file
      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
    } catch (e) {
      // Close progress dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred during compression: $e'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          );
        },
      );
    }
  }

  // Helper method to add a directory and its contents to an archive
  Future<void> _addDirectoryToArchive(Archive archive, String dirPath, String archivePath) async {
    final dir = Directory(dirPath);
    final entities = await dir.list(recursive: false).toList();

    for (final entity in entities) {
      final relativePath = path.join(archivePath, path.basename(entity.path));

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity.path, relativePath);
      }
    }
  }

  /// Rename a file or directory
  Future<void> renameFileSystemItem(WidgetRef ref, FileSystemItem item, String newName, BuildContext context) async {
    if (newName.isEmpty || newName == item.name) return;

    final service = ref.read(fileSystemServiceProvider);

    // Check if a file with this name already exists
    final directory = path.dirname(item.path);
    final newPath = path.join(directory, newName);

    if (File(newPath).existsSync() || Directory(newPath).existsSync()) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('The file "$newName" already exists.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          );
        },
      );
      return;
    }

    final success = await service.renameItem(item, newName);

    if (!success) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to rename the file.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          );
        },
      );
    }
  }
}
