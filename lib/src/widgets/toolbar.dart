import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/src/base_state.dart';
import 'package:macos_file_manager/src/favorite_event.dart';
import 'package:macos_file_manager/src/navigation_event.dart';

class Toolbar extends HookConsumerWidget with BaseState, NavigationEvent, FavoriteEvent {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final history = directoryHistory(ref);
    final currentDir = currentDirectory(ref);

    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.any((fav) => fav.path == currentDir);
    String formatPath(String path) {
      final parts = path.split('/').where((part) => part.isNotEmpty).toList();

      if (parts.length <= 4) {
        return path;
      } else {
        final lastFourParts = parts.sublist(parts.length - 4);

        // Show ellipsis with the first folder
        return '/${parts.first}/.../${lastFourParts.join('/')}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: history.canGoBack ? () => navigateBack(ref) : null,
            tooltip: 'Back',
            color: Theme.of(context).iconTheme.color,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: history.canGoForward ? () => navigateForward(ref) : null,
            tooltip: 'Forward',
            color: Theme.of(context).iconTheme.color,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: history.canGoUpperDir ? () => navigateUp(ref) : null,
            tooltip: 'Parent Directory',
            color: Theme.of(context).iconTheme.color,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => navigateToHome(ref),
            tooltip: 'Home Directory',
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formatPath(currentDir),
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Theme.of(context).iconTheme.color,
                      size: 20,
                    ),
                    onPressed: () => toggleFavoriteDirectory(ref, currentDir),
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                ],
              ),
            ),
          ),

          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Theme.of(context).iconTheme.color),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            tooltip: isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          ),
        ],
      ),
    );
  }
}
