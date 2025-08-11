import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_category_config.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';
import 'package:macos_file_manager/widgets/dialogs/add_extension_dialog.dart';
import 'package:macos_file_manager/widgets/dialogs/edit_extension_dialog.dart';
import 'package:macos_file_manager/widgets/dialogs/import_config_dialog.dart';
import 'package:macos_file_manager/widgets/keyword_mapping_tab.dart';

class FileCategorySettingsDialog extends ConsumerWidget {
  const FileCategorySettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Dialog(
        child: Container(
          width: 900,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    AppStrings.fileCategorySettings,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),

              // 탭 바
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  tabs: const [
                    Tab(icon: Icon(Icons.extension), text: '확장자 매핑'),
                    Tab(icon: Icon(Icons.search), text: '키워드 매핑'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              // 탭 뷰
              const Expanded(child: TabBarView(children: [_ExtensionMappingTab(), KeywordMappingTab()])),

              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(onPressed: () => _showResetDialog(context, ref), child: const Text(AppStrings.reset)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _exportConfig(context, ref),
                    child: const Text(AppStrings.exportSettings),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _importConfig(context, ref),
                    child: const Text(AppStrings.importSettings),
                  ),
                  const Spacer(),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.complete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.resetSettingsTitle),
            content: const Text(AppStrings.resetSettingsMessage),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
              TextButton(
                onPressed: () {
                  ref.read(fileCategoryConfigProvider.notifier).resetToDefault();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text(AppStrings.settingsResetMessage)));
                },
                child: const Text(AppStrings.reset),
              ),
            ],
          ),
    );
  }

  void _exportConfig(BuildContext context, WidgetRef ref) {
    final config = ref.read(fileCategoryConfigProvider.notifier).exportConfig();
    Clipboard.setData(ClipboardData(text: config));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.settingsExportedMessage)));
  }

  void _importConfig(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const ImportConfigDialog());
  }
}

class _ExtensionMappingTab extends ConsumerWidget {
  const _ExtensionMappingTab();

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
                label: const Text(AppStrings.addExtensionTitle),
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
          child: const Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(AppStrings.extensionLabel, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 150,
                child: Text(AppStrings.categoryLabel, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 80, child: Text('타입', style: TextStyle(fontWeight: FontWeight.bold))),
              Spacer(),
              SizedBox(width: 100, child: Text('작업', style: TextStyle(fontWeight: FontWeight.bold))),
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
                            tooltip: AppStrings.edit,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          if (mapping.isCustom)
                            IconButton(
                              onPressed: () => _removeExtension(ref, mapping.extension),
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              tooltip: AppStrings.delete,
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
    showDialog(context: context, builder: (context) => AddExtensionDialog(categories: categories)).then((result) {
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
      builder: (context) => EditExtensionDialog(mapping: mapping, categories: categories),
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
