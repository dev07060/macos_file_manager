import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/src/home_event.dart';
import 'package:macos_file_manager/src/home_state.dart';

class Toolbar extends HookConsumerWidget with HomeState, HomeEvent {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = directoryHistory(ref);
    final currentDir = currentDirectory(ref);

    // Watch the favorites list to respond to changes
    final favorites = ref.watch(favoritesProvider);

    // Determine if current directory is a favorite by checking the watched favorites list
    final isFavorite = favorites.any((fav) => fav.path == currentDir);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: history.canGoBack ? () => navigateBack(ref) : null,
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: history.canGoForward ? () => navigateForward(ref) : null,
            tooltip: 'Forward',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: history.canGoUpperDir ? () => navigateUp(ref) : null,
            tooltip: 'Parent Directory',
          ),
          IconButton(icon: const Icon(Icons.home), onPressed: () => navigateToHome(ref), tooltip: 'Home Directory'),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(currentDir, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
          ),
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : null),
            onPressed: () => toggleFavoriteDirectory(ref, currentDir),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
    );
  }
}
