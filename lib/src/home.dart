import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/src/widgets/favorites_section.dart';
import 'package:path/path.dart' as path;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'home_event.dart';
import 'home_state.dart';

part 'widgets/file_details.dart';
part 'widgets/file_item.dart';
part 'widgets/toolbar.dart';

class HomePage extends HookConsumerWidget with HomeState, HomeEvent {
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          children: [
                            const Text('Current Directory', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            // Show action icons only when items are selected
                            if (selectedCount > 0) ...[
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                tooltip: 'Delete selected items',
                                onPressed: () => deleteSelectedItems(ref, context),
                              ),
                              // Compress button
                              IconButton(
                                icon: const Icon(Icons.archive_outlined, size: 20),
                                tooltip: 'Compress selected items',
                                onPressed: () => compressSelectedItems(ref, context),
                              ),
                            ],
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
                Container(width: 1, color: Colors.grey.shade300),
                // File details section (right side)
                const Expanded(child: FileDetails()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
