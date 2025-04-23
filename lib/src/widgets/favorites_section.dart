import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/theme_provider.dart'; // 테마 Provider 추가
import 'package:macos_file_manager/src/drag_drop_items_event.dart';
import 'package:macos_file_manager/src/navigation_event.dart';
import 'package:path/path.dart' as path;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class FavoritesSection extends HookConsumerWidget with NavigationEvent, DragDropItemsEvent {
  const FavoritesSection({super.key});

  static const double _maxCollapsedHeight = 216; // (40 * 5 + 16)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final currentDirectory = ref.watch(currentDirectoryProvider);

    // 테마 모드 상태 확인
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final isExpanded = useState(true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // 테마에 맞는 색상 사용
            color: Theme.of(context).appBarTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                'Favorites',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // 테마에 맞는 색상 사용
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  // 테마에 맞는 색상 사용
                  color: Theme.of(context).iconTheme.color,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  isExpanded.value = !isExpanded.value;
                },
                tooltip: isExpanded.value ? 'Collapse' : 'Expand',
              ),
            ],
          ),
        ),

        if (isExpanded.value)
          if (favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No favorites',
                style: TextStyle(
                  // 테마에 맞는 색상 사용
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: _maxCollapsedHeight),
              // 테마에 맞는 배경색 사용
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
                        // 호버 효과 색상 지정
                        hoverColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                        onTap: () => navigateToDirectory(ref, favorite.path),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              // 폴더 아이콘 색상은 일관성을 위해 그대로 유지
                              const Icon(Icons.folder, color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  favorite.name,
                                  overflow: TextOverflow.ellipsis,
                                  // 테마에 맞는 텍스트 색상 사용
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                ),
                              ),
                              if (isCurrentLocation)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    // 현재 위치 표시 배경색 테마에 맞게 조정
                                    color:
                                        isDarkMode
                                            ? Colors.blue.shade800.withOpacity(0.3)
                                            : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'current location',
                                    style: TextStyle(
                                      // 현재 위치 표시 텍스트 색상 테마에 맞게 조정
                                      color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
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
        // 테마에 맞는 구분선 색상
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
