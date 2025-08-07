import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/events/base_event.dart';
import 'package:macos_file_manager/events/file_operation_event.dart';
import 'package:macos_file_manager/events/file_organization_event.dart';
import 'package:macos_file_manager/events/navigation_event.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/state/base_state.dart';
import 'package:macos_file_manager/widgets/favorites_section.dart';
import 'package:macos_file_manager/widgets/file_category_settings.dart';
import 'package:macos_file_manager/widgets/file_details.dart';
import 'package:macos_file_manager/widgets/file_item.dart';
import 'package:macos_file_manager/widgets/toolbar.dart';

class HomePage extends HookConsumerWidget
    with BaseState, BaseEvent, NavigationEvent, FileOperationEvent, FileOrganizationEvent {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() async {
        final desktopPath = await getDesktopPath();
        await navigateToDirectory(ref, desktopPath);
      });
      return null;
    }, const []);

    final items = fileSystemItems(ref);
    final selectedCount = ref.watch(selectedItemsCountProvider);
    final path = ref.watch(currentDirectoryProvider.notifier).state;
    List<String> parts = path.split('/');
    String result = parts[parts.length - 1];

    return Scaffold(
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: Row(
              children: [
                // File/Folder list section (left side)
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      // Add Favorites section above the file list
                      const FavoritesSection(),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  result,
                                  maxLines: 1,
                                  style: TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Show action icons only when items are selected
                            if (selectedCount > 0) ...[
                              // Delete button
                              Expanded(
                                flex: 3,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  tooltip: 'Delete selected items',
                                  onPressed: () => deleteSelectedItems(ref, context),
                                ),
                              ),
                              // Compress button
                              Expanded(
                                flex: 3,
                                child: IconButton(
                                  icon: const Icon(Icons.archive_outlined, size: 20),
                                  tooltip: 'Compress selected items',
                                  onPressed: () => compressSelectedItems(ref, context),
                                ),
                              ),
                            ],

                            IconButton(
                              icon: Icon(
                                Icons.account_tree,
                                size: 20,
                                color: selectedCount > 1 ? Theme.of(context).disabledColor : null,
                              ),
                              tooltip:
                                  selectedCount > 1
                                      ? 'Tree-view disabled (multiple items selected)'
                                      : 'Show tree-view from dir',
                              onPressed:
                                  selectedCount > 1
                                      ? null
                                      : () {
                                        ref.read(searchQueryProvider.notifier).state = null;
                                        ref.read(treeViewNotifierProvider.notifier).showTreeView(path);
                                      },
                            ),

                            IconButton(
                              icon: const Icon(Icons.auto_awesome, size: 20),
                              tooltip: 'Organize files with AI',
                              onPressed: () {
                                // 아직 구현되지 않은 이벤트 핸들러 호출
                                organizeDirectoryWithAI(ref, context);
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.settings, size: 20),
                              tooltip: 'File category settings',
                              onPressed: () {
                                showDialog(context: context, builder: (context) => const FileCategorySettingsDialog());
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return FileItem(item: items[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(width: 1, color: Theme.of(context).dividerColor),
                // File details section (right side)
                Expanded(child: FileDetails()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
