import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';

/// 파일 정리 미리보기 다이얼로그
class FileOrganizationPreviewDialog extends StatelessWidget {
  final List<FileOrganizationResult> results;

  const FileOrganizationPreviewDialog({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.fileOrganizationProposal),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: CategoryPreviewWidget(results: results),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(AppStrings.cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text(AppStrings.confirm)),
      ],
    );
  }
}

/// 카테고리 미리보기를 위한 StatefulWidget (좌우 프레임 구조)
class CategoryPreviewWidget extends StatefulWidget {
  final List<FileOrganizationResult> results;

  const CategoryPreviewWidget({super.key, required this.results});

  @override
  State<CategoryPreviewWidget> createState() => _CategoryPreviewWidgetState();
}

class _CategoryPreviewWidgetState extends State<CategoryPreviewWidget> {
  String? selectedCategory;
  late Map<String, List<FileOrganizationResult>> categoryGroups;
  final Set<String> selectedFiles = <String>{}; // 선택된 파일들의 경로

  @override
  void initState() {
    super.initState();
    // 카테고리별로 그룹화
    categoryGroups = {};
    for (final result in widget.results) {
      categoryGroups.putIfAbsent(result.category, () => []).add(result);
    }

    // 첫 번째 카테고리를 기본 선택
    if (categoryGroups.isNotEmpty) {
      selectedCategory = categoryGroups.keys.first;
    }
  }

  void _excludeSelectedFiles() {
    // 정리에서 제외 - 실제로 리스트에서 제거
    setState(() {
      // 선택된 파일들을 각 카테고리에서 제거
      for (final filePath in selectedFiles) {
        for (final category in categoryGroups.keys) {
          categoryGroups[category]!.removeWhere((result) => result.filePath == filePath);
        }
      }

      // 빈 카테고리 제거
      categoryGroups.removeWhere((key, value) => value.isEmpty);

      // 현재 선택된 카테고리가 제거되었다면 첫 번째 카테고리로 변경
      if (selectedCategory != null && !categoryGroups.containsKey(selectedCategory)) {
        selectedCategory = categoryGroups.isNotEmpty ? categoryGroups.keys.first : null;
      }

      selectedFiles.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.filesExcludedFromOrganization)));
  }

  Future<void> _deleteSelectedFiles() async {
    // 파일 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.fileDeleteConfirmTitle),
            content: Text(AppStrings.fileDeleteConfirmContent(selectedFiles.length)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(AppStrings.cancel)),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _performFileDeletion();
    }
  }

  Future<void> _performFileDeletion() async {
    int deletedCount = 0;
    int failedCount = 0;

    // 실제 파일 삭제 수행
    for (final filePath in selectedFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
        }
      } catch (e) {
        failedCount++;
        developer.log('Failed to delete file $filePath: $e');
      }
    }

    // UI에서 삭제된 파일들 제거
    setState(() {
      // 선택된 파일들을 각 카테고리에서 제거
      for (final filePath in selectedFiles) {
        for (final category in categoryGroups.keys) {
          categoryGroups[category]!.removeWhere((result) => result.filePath == filePath);
        }
      }

      // 빈 카테고리 제거
      categoryGroups.removeWhere((key, value) => value.isEmpty);

      // 현재 선택된 카테고리가 제거되었다면 첫 번째 카테고리로 변경
      if (selectedCategory != null && !categoryGroups.containsKey(selectedCategory)) {
        selectedCategory = categoryGroups.isNotEmpty ? categoryGroups.keys.first : null;
      }

      selectedFiles.clear();
    });

    // 결과 메시지 표시
    if (failedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.filesDeletedSuccessfully(deletedCount))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.filesDeletedWithErrors(deletedCount, failedCount)),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 왼쪽 프레임: 폴더명 목록
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  child: Text(
                    AppStrings.folderName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children:
                        categoryGroups.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final categoryEntry = entry.value;
                          final categoryName = categoryEntry.key;
                          final filesCount = categoryEntry.value.length;
                          final isSelected = selectedCategory == categoryName;

                          return Container(
                            color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                            child: ListTile(
                              title: Text(categoryName),
                              subtitle: Text('$filesCount개 ${AppStrings.fileName}'),
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedCategory = categoryName;
                                });
                              },
                              dense: true,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 오른쪽 프레임: 선택된 폴더의 파일 목록
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 (파일명 + 액션 버튼들)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.fileName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // 선택된 파일이 있을 때만 액션 버튼 표시
                      if (selectedFiles.isNotEmpty) ...[
                        Text(
                          AppStrings.filesSelected(selectedFiles.length),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _excludeSelectedFiles,
                          icon: const Icon(Icons.remove_circle_outline, size: 16),
                          label: const Text(AppStrings.exclude),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: _deleteSelectedFiles,
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: const Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 파일 목록
                Expanded(
                  child:
                      selectedCategory != null && categoryGroups[selectedCategory] != null
                          ? ListView(
                            children:
                                categoryGroups[selectedCategory]!.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final result = entry.value;
                                  final isSelected = selectedFiles.contains(result.filePath);

                                  return Container(
                                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                    child: CheckboxListTile(
                                      title: Text(result.fileName),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedFiles.add(result.filePath);
                                          } else {
                                            selectedFiles.remove(result.filePath);
                                          }
                                        });
                                      },
                                      dense: true,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                  );
                                }).toList(),
                          )
                          : const Center(child: Text(AppStrings.selectFolder)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
