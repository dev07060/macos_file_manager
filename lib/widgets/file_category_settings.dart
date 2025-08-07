import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';

class FileCategorySettingsDialog extends ConsumerWidget {
  const FileCategorySettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('파일 확장자 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _ExtensionMappingTab()),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: () => _showResetDialog(context, ref), child: const Text('기본값으로 리셋')),
                const SizedBox(width: 8),
                TextButton(onPressed: () => _exportConfig(context, ref), child: const Text('설정 내보내기')),
                const SizedBox(width: 8),
                TextButton(onPressed: () => _importConfig(context, ref), child: const Text('설정 가져오기')),
                const Spacer(),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('완료')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('설정 리셋'),
            content: const Text('모든 설정을 기본값으로 되돌리시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
              TextButton(
                onPressed: () {
                  ref.read(fileCategoryConfigProvider.notifier).resetToDefault();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정이 기본값으로 리셋되었습니다.')));
                },
                child: const Text('리셋'),
              ),
            ],
          ),
    );
  }

  void _exportConfig(BuildContext context, WidgetRef ref) {
    final config = ref.read(fileCategoryConfigProvider.notifier).exportConfig();
    Clipboard.setData(ClipboardData(text: config));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정이 클립보드에 복사되었습니다.')));
  }

  void _importConfig(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const _ImportConfigDialog());
  }
}

class _ExtensionMappingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappings = ref.watch(extensionMappingsProvider);
    final categories = ref.watch(availableCategoriesProvider);

    return Column(
      children: [
        // 헤더와 추가 버튼
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                '확장자 매핑 (${mappings.length}개)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddExtensionDialog(context, ref, categories),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('확장자 추가'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ],
          ),
        ),

        // 테이블 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 100, child: Text('확장자', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 150, child: Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 80, child: Text('타입', style: TextStyle(fontWeight: FontWeight.bold))),
              const Spacer(),
              const SizedBox(width: 100, child: Text('작업', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        // 테이블 내용
        Expanded(
          child: ListView.builder(
            itemCount: mappings.length,
            itemBuilder: (context, index) {
              final mapping = mappings[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .3))),
                  color:
                      index % 2 == 0
                          ? null
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '.${mapping.extension}',
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(width: 150, child: Text(mapping.category)),
                    SizedBox(
                      width: 80,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              mapping.isCustom ? Colors.blue.withValues(alpha: .1) : Colors.grey.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                mapping.isCustom
                                    ? Colors.blue.withValues(alpha: .3)
                                    : Colors.grey.withValues(alpha: .3),
                          ),
                        ),
                        child: Text(
                          mapping.isCustom ? '사용자' : '기본',
                          style: TextStyle(
                            fontSize: 12,
                            color: mapping.isCustom ? Colors.blue : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showEditExtensionDialog(context, ref, mapping, categories),
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: '수정',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          if (mapping.isCustom)
                            IconButton(
                              onPressed: () => _removeExtension(ref, mapping.extension),
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              tooltip: '삭제',
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddExtensionDialog(BuildContext context, WidgetRef ref, List<String> categories) {
    showDialog(context: context, builder: (context) => _AddExtensionDialog(categories: categories)).then((result) {
      if (result != null) {
        ref.read(fileCategoryConfigProvider.notifier).addExtensionMapping(result['extension'], result['category']);
      }
    });
  }

  void _showEditExtensionDialog(
    BuildContext context,
    WidgetRef ref,
    ExtensionMapping mapping,
    List<String> categories,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EditExtensionDialog(mapping: mapping, categories: categories),
    ).then((result) {
      if (result != null) {
        ref.read(fileCategoryConfigProvider.notifier).updateExtensionMapping(mapping.extension, result);
      }
    });
  }

  void _removeExtension(WidgetRef ref, String extension) {
    ref.read(fileCategoryConfigProvider.notifier).removeExtensionMapping(extension);
  }
}

// 다이얼로그 위젯들
class _AddExtensionDialog extends HookConsumerWidget {
  final List<String> categories;

  const _AddExtensionDialog({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionController = useTextEditingController();
    final selectedCategory = useState<String?>(null);

    return AlertDialog(
      title: const Text('확장자 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: extensionController,
            decoration: const InputDecoration(labelText: '확장자', hintText: 'pdf, jpg, txt 등 (점 제외)'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCategory.value,
            decoration: const InputDecoration(labelText: '카테고리'),
            items:
                categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
            onChanged: (value) => selectedCategory.value = value,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        TextButton(
          onPressed:
              selectedCategory.value != null && extensionController.text.isNotEmpty
                  ? () => Navigator.of(
                    context,
                  ).pop({'extension': extensionController.text, 'category': selectedCategory.value})
                  : null,
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class _EditExtensionDialog extends HookConsumerWidget {
  final ExtensionMapping mapping;
  final List<String> categories;

  const _EditExtensionDialog({required this.mapping, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(mapping.category);

    return AlertDialog(
      title: Text('확장자 수정: .${mapping.extension}'),
      content: DropdownButtonFormField<String>(
        value: selectedCategory.value,
        decoration: const InputDecoration(labelText: '카테고리'),
        items:
            categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
        onChanged: (value) => selectedCategory.value = value,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.of(context).pop(selectedCategory.value), child: const Text('수정')),
      ],
    );
  }
}

class _ImportConfigDialog extends HookConsumerWidget {
  const _ImportConfigDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = useTextEditingController();

    return AlertDialog(
      title: const Text('설정 가져오기'),
      content: SizedBox(
        width: 400,
        height: 200,
        child: TextField(
          controller: configController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            labelText: '설정 JSON',
            hintText: '내보낸 설정 JSON을 붙여넣으세요',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        TextButton(
          onPressed: () async {
            final success = await ref.read(fileCategoryConfigProvider.notifier).importConfig(configController.text);

            Navigator.of(context).pop();

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정을 성공적으로 가져왔습니다.')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정 가져오기에 실패했습니다.')));
            }
          },
          child: const Text('가져오기'),
        ),
      ],
    );
  }
}
