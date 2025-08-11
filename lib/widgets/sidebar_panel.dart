import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/events/file_operation_event.dart';
import 'package:macos_file_manager/events/file_organization_event.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/routes/app_routes.dart';
import 'package:macos_file_manager/widgets/favorites_section.dart';
import 'package:macos_file_manager/widgets/file_category_settings.dart';
import 'package:macos_file_manager/widgets/file_item.dart';

class SidebarPanel extends HookConsumerWidget with FileOperationEvent, FileOrganizationEvent {
  const SidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(fileSystemItemListProvider);
    final selectedCount = ref.watch(selectedItemsCountProvider);
    final path = ref.watch(currentDirectoryProvider);
    final result = path.split('/').isNotEmpty ? path.split('/').last : '';

    return RepaintBoundary(
      child: Column(
        children: [
          const FavoritesSection(),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                      child: Text(
                        result,
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedCount > 0) ...[
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: AppStrings.deleteSelectedItems,
                            onPressed: () => deleteSelectedItems(ref, context),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.archive_outlined, size: 20),
                            tooltip: AppStrings.compressSelectedItems,
                            onPressed: () => compressSelectedItems(ref, context),
                          ),
                        ),
                      ],
                      if (selectedCount <= 1)
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.account_tree, size: 20),
                            tooltip: AppStrings.showTreeView,
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = null;
                              ref.read(treeViewNotifierProvider.notifier).showTreeView(path);
                            },
                          ),
                        ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          tooltip: AppStrings.organizeWithAI,
                          onPressed: () => organizeDirectoryWithAI(ref, context),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.web, size: 20),
                          tooltip: 'Open Web Browser',
                          onPressed: () async {
                            // Add smooth navigation with potential loading state
                            await Navigator.of(context).pushNamed(AppRoutes.webview);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.settings, size: 20),
                          tooltip: AppStrings.fileCategorySettings,
                          onPressed: () {
                            showDialog(context: context, builder: (context) => const FileCategorySettingsDialog());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => FileItem(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}
