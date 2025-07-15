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
    final settings = ref.read(fileOrganizationSettingsProvider);

    if (!context.mounted) return;

    if (fileSystemItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('정리할 파일이 없습니다.')));
      return;
    }

    // 1. 정리 방식 선택 (설정에 따라 자동 선택 또는 다이얼로그 표시)
    OrganizationMethodInfo? selectedMethod;
    if (settings.rememberChoice && settings.preferredMethod != null) {
      selectedMethod = VertexAIService.organizationMethods.firstWhere(
        (method) => method.method == settings.preferredMethod,
      );
    } else {
      selectedMethod = await _showOrganizationMethodDialog(context, ref);
      if (selectedMethod == null) return;
    }

         // 2. 사용자 정의 정리인 경우 추가 옵션 수집
     String? customPrompt;
     if (selectedMethod.method == OrganizationMethod.custom) {
       customPrompt = await _showCustomPromptDialog(context, ref);
       if (customPrompt == null || customPrompt.isEmpty) return;
     }

    // 3. AI 분석 시작
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('AI가 ${selectedMethod.displayName}으로 파일을 분석 중입니다...')
          ],
        ),
      ),
    );

    // 되돌리기를 위한 파일 이동 기록
    final List<Map<String, String>> movedFilesLog = [];

    try {
      final aiService = await ref.read(vertexAIServiceProvider.future);
      final Map<String, String> fileToFolderMap = {};

      // 4. 파일별 분석 및 분류
      for (final item in fileSystemItems) {
        if (item.type == FileSystemItemType.file) {
          String snippet = "";
          Map<String, dynamic>? metadata;

          try {
            // 파일 메타데이터 수집
            final fileStat = await File(item.path).stat();
            metadata = {
              'size': fileStat.size,
              'creationDate': fileStat.changed,
              'modificationDate': fileStat.modified,
            };

            // 텍스트 기반 파일이면 내용 일부를 읽음
            if (!FileConstants.imageExtensions.contains(item.fileExtension.toLowerCase())) {
              snippet = await File(item.path).readAsString();
              if (snippet.length > 500) {
                snippet = snippet.substring(0, 500);
              }
            }
          } catch (e) {
            developer.log('Failed to read file info for ${item.name}: $e');
          }

          // AI로 파일 분류
          final folderName = await aiService.organizeFile(
            item.name,
            snippet,
            selectedMethod.method,
            customPrompt: customPrompt,
            fileMetadata: metadata,
          );

          if (folderName != null && folderName.isNotEmpty) {
            fileToFolderMap[item.path] = folderName;
          }
        }
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // AI 분석 로딩 다이얼로그 닫기

      if (fileToFolderMap.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI가 분류할 파일을 찾지 못했습니다.')));
        }
        return;
      }

      // 5. 분류 결과 미리보기 및 확인
      final confirmed = await _showOrganizationPreview(context, fileToFolderMap, selectedMethod);
      if (confirmed != true) return;

      // 6. 파일 이동 실행
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('파일을 이동 중입니다...')
            ],
          ),
        ),
      );

      try {
        for (final entry in fileToFolderMap.entries) {
          final sourcePath = entry.key;
          final folderName = entry.value;
          final targetDir = path.join(currentDir, folderName);

          // 대상 폴더가 없으면 생성
          await Directory(targetDir).create(recursive: true);

          final fileName = path.basename(sourcePath);
          final destinationPath = path.join(targetDir, fileName);

          // 파일명 중복 처리
          String finalDestinationPath = destinationPath;
          int counter = 1;
          while (await File(finalDestinationPath).exists()) {
            final nameWithoutExt = path.basenameWithoutExtension(fileName);
            final ext = path.extension(fileName);
            finalDestinationPath = path.join(targetDir, '${nameWithoutExt}_$counter$ext');
            counter++;
          }

          movedFilesLog.add({'originalPath': sourcePath, 'newPath': finalDestinationPath});
          await File(sourcePath).rename(finalDestinationPath);
        }
      } finally {
        if (context.mounted) {
          Navigator.of(context).pop(); // 파일 이동 로딩 다이얼로그 닫기
        }
      }

      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
      if (!context.mounted) return;

      // 7. 완료 후 되돌리기/유지하기 옵션 제공
      final action = await _showCompletionDialog(context);
      if (action == 'undo') {
        await _undoFileMovement(context, movedFilesLog, ref, currentDir);
      } else if (action == 'keep') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파일 정리가 완료되었습니다.')));
        }
      }

    } catch (e) {
      developer.log('Error during AI file organization: $e');
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI 파일 정리 중 오류 발생: $e')));
      }
    }
  }

  // 정리 방식 선택 다이얼로그
  Future<OrganizationMethodInfo?> _showOrganizationMethodDialog(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(fileOrganizationSettingsProvider);
    bool rememberChoice = settings.rememberChoice;
    OrganizationMethodInfo? selectedMethod;

    return await showDialog<OrganizationMethodInfo>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('파일 정리 방식 선택'),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: VertexAIService.organizationMethods.length,
                    itemBuilder: (context, index) {
                      final method = VertexAIService.organizationMethods[index];
                      final isSelected = selectedMethod == method;
                      final isPreferred = settings.preferredMethod == method.method;
                      
                      return Card(
                        elevation: isSelected ? 2 : 0,
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                        child: ListTile(
                          leading: Text(method.icon, style: const TextStyle(fontSize: 24)),
                          title: Row(
                            children: [
                              Text(method.displayName),
                              if (isPreferred) 
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.star, size: 16, color: Colors.orange),
                                ),
                            ],
                          ),
                          subtitle: Text(method.description),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedMethod = method;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                CheckboxListTile(
                  title: const Text('선택한 방식을 기억하기'),
                  subtitle: const Text('다음에 자동으로 같은 방식으로 정리합니다'),
                  value: rememberChoice,
                  onChanged: (value) {
                    setState(() {
                      rememberChoice = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: selectedMethod == null ? null : () async {
                if (rememberChoice && selectedMethod != null) {
                  await ref.read(fileOrganizationSettingsProvider.notifier).savePreferredMethod(selectedMethod!.method);
                  await ref.read(fileOrganizationSettingsProvider.notifier).setRememberChoice(true);
                }
                Navigator.of(context).pop(selectedMethod);
              },
              child: const Text('선택'),
            ),
          ],
        ),
      ),
    );
  }

  // 사용자 정의 프롬프트 입력 다이얼로그
  Future<String?> _showCustomPromptDialog(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(fileOrganizationSettingsProvider);
    final controller = TextEditingController(text: settings.lastCustomPrompt ?? '');
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 정의 정리 규칙'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI에게 파일을 어떻게 정리하라고 지시하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '예: 파일을 프로그래밍 언어별로 분류하세요',
                border: OutlineInputBorder(),
                helperText: '구체적이고 명확한 지시를 해주세요',
              ),
              maxLines: 4,
              autofocus: true,
            ),
            if (settings.lastCustomPrompt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16),
                  const SizedBox(width: 8),
                  const Text('이전 사용 기록:', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  settings.lastCustomPrompt!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final prompt = controller.text.trim();
              if (prompt.isNotEmpty) {
                await ref.read(fileOrganizationSettingsProvider.notifier).saveCustomPrompt(prompt);
              }
              Navigator.of(context).pop(prompt);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 분류 결과 미리보기 다이얼로그
  Future<bool?> _showOrganizationPreview(
    BuildContext context,
    Map<String, String> fileToFolderMap,
    OrganizationMethodInfo method,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        // 폴더별 파일 목록 생성
        final Map<String, List<String>> folderToFileList = {};
        fileToFolderMap.forEach((filePath, folderName) {
          folderToFileList.putIfAbsent(folderName, () => []).add(filePath);
        });

        return AlertDialog(
          title: Text('${method.displayName} 결과'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: folderToFileList.entries.map((entry) {
                  final folderName = entry.key;
                  final files = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '$folderName (${files.length}개)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...files.map((filePath) => Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text('• ${path.basename(filePath)}'),
                      )),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('정리 시작'),
            ),
          ],
        );
      },
    );
  }

  // 완료 후 행동 선택 다이얼로그
  Future<String?> _showCompletionDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('파일 정리 완료'),
        content: const Text('파일 정리가 완료되었습니다. 어떻게 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('undo'),
            child: const Text('되돌리기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('keep'),
            child: const Text('유지하기'),
          ),
        ],
      ),
    );
  }

  // 파일 이동 되돌리기
  Future<void> _undoFileMovement(
    BuildContext context,
    List<Map<String, String>> movedFilesLog,
    WidgetRef ref,
    String currentDir,
  ) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('파일을 되돌리는 중입니다...')
          ],
        ),
      ),
    );

    try {
      for (final logEntry in movedFilesLog) {
        final originalPath = logEntry['originalPath']!;
        final newPath = logEntry['newPath']!;
        await File(newPath).rename(originalPath);
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파일 위치를 되돌렸습니다.')));
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
