// lib/providers/favorites_provider.dart
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/favorite_directory.dart';

// Default directories to include in favorites
List<FavoriteDirectory> _getDefaultFavorites() {
  final homeDir = Platform.environment['HOME'];
  if (homeDir == null) return [];

  return [
    FavoriteDirectory(path: '$homeDir/Desktop', name: 'Desktop', isSystem: true),
    FavoriteDirectory(path: '$homeDir/Documents', name: 'Documents', isSystem: true),
    FavoriteDirectory(path: '$homeDir/Downloads', name: 'Downloads', isSystem: true),
  ];
}

class FavoritesNotifier extends StateNotifier<List<FavoriteDirectory>> {
  FavoritesNotifier() : super(_getDefaultFavorites());

  void addFavorite(String path, String name) {
    // Don't add if it already exists
    if (state.any((fav) => fav.path == path)) return;

    state = [...state, FavoriteDirectory(path: path, name: name, isSystem: false)];
  }

  void removeFavorite(String path) {
    // Don't remove system favorites
    if (state.any((fav) => fav.path == path && fav.isSystem)) return;

    state = state.where((fav) => fav.path != path).toList();
  }

  bool isFavorite(String path) {
    return state.any((fav) => fav.path == path);
  }

  void toggleFavorite(String path, String name) {
    if (isFavorite(path)) {
      removeFavorite(path);
    } else {
      addFavorite(path, name);
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteDirectory>>((ref) {
  return FavoritesNotifier();
});
