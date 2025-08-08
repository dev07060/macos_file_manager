import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/events/drag_drop_items_event.dart';
import 'package:macos_file_manager/events/navigation_event.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:path/path.dart' as path;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class FavoritesSection extends HookConsumerWidget with NavigationEvent, DragDropItemsEvent {
  const FavoritesSection({super.key});

  static const double _maxCollapsedHeight = 216; // (40 * 5 + 16)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final currentDirectory = ref.watch(currentDirectoryProvider);

    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final isExpanded = useState(true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                AppStrings.favorites,
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  isExpanded.value = !isExpanded.value;
                },
                tooltip: isExpanded.value ? AppStrings.collapse : AppStrings.expand,
              ),
            ],
          ),
        ),

        if (isExpanded.value)
          if (favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppStrings.noFavorites,
                style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: _maxCollapsedHeight),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.builder(
                shrinkWrap: true,
                physics:
                    favorites.length > 5 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final favorite = favorites[index];
                  final isCurrentLocation = favorite.path == currentDirectory;

                  return _buildDroppableFavorite(
                    context,
                    ref,
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        hoverColor: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: .05),
                        onTap: () => navigateToDirectory(ref, favorite.path),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.folder, color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  favorite.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                ),
                              ),
                              if (isCurrentLocation)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? Colors.blue.shade800.withValues(alpha: .3)
                                            : Colors.blue.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    AppStrings.currentLocation,
                                    style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    favorite.path,
                  );
                },
              ),
            ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }

  // Make favorite folders accept drops
  Widget _buildDroppableFavorite(BuildContext context, WidgetRef ref, Widget child, String directoryPath) {
    return DropRegion(
      formats: const [...Formats.standardFormats],
      hitTestBehavior: HitTestBehavior.translucent,
      onDropOver: (event) {
        // Show visual indicator that this is a drop target
        return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
      },
      onPerformDrop: (event) async {
        // Create a FileSystemItem representation of the favorite directory
        final favoriteItem = FileSystemItem(
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          size: 0,
          name: path.basename(directoryPath),
          path: directoryPath,
          type: FileSystemItemType.directory,
          isSelected: false,
        );
        await handleFileDrop(ref, context, event, favoriteItem.path);
      },
      child: child,
    );
  }
}
