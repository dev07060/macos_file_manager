import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/favorite_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _favoritesKey = 'favorites_list';

class FavoritesNotifier extends StateNotifier<List<FavoriteDirectory>> {
  final SharedPreferences _prefs;
  List<FavoriteDirectory> _getDefaultFavorites() {
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null) return [];

    return [
      FavoriteDirectory(path: '$homeDir/Desktop', name: 'Desktop', isSystem: true),
      FavoriteDirectory(path: '$homeDir/Documents', name: 'Documents', isSystem: true),
      FavoriteDirectory(path: '$homeDir/Downloads', name: 'Downloads', isSystem: true),
    ];
  }

  FavoritesNotifier(this._prefs) : super([]) {
    _loadFavorites();
  }

  void _loadFavorites() {
    final defaultFavorites = _getDefaultFavorites();

    final storedFavorites = _prefs.getStringList(_favoritesKey);

    if (storedFavorites == null || storedFavorites.isEmpty) {
      state = defaultFavorites;
      _saveFavorites();
      return;
    }

    final userFavorites =
        storedFavorites.map((json) => _favoriteFromJson(json)).whereType<FavoriteDirectory>().toList();

    final allFavorites = <FavoriteDirectory>[];

    allFavorites.addAll(defaultFavorites);

    for (final favorite in userFavorites) {
      if (!favorite.isSystem && !allFavorites.any((f) => f.path == favorite.path)) {
        allFavorites.add(favorite);
      }
    }

    state = allFavorites;
  }

  void _saveFavorites() {
    final userFavorites =
        state.where((favorite) => !favorite.isSystem).map((favorite) => _favoriteToJson(favorite)).toList();

    _prefs.setStringList(_favoritesKey, userFavorites);
  }

  // Convert FavoriteDirectory to JSON
  String _favoriteToJson(FavoriteDirectory favorite) {
    return jsonEncode({'path': favorite.path, 'name': favorite.name, 'isSystem': favorite.isSystem});
  }

  // Convert JSON to FavoriteDirectory
  FavoriteDirectory? _favoriteFromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return FavoriteDirectory(
        path: map['path'] as String,
        name: map['name'] as String,
        isSystem: map['isSystem'] as bool,
      );
    } catch (e) {
      log('Error deserializing favorite: $e');
      return null;
    }
  }

  void addFavorite(String path, String name) {
    // Don't add if it already exists
    if (state.any((fav) => fav.path == path)) return;

    state = [...state, FavoriteDirectory(path: path, name: name, isSystem: false)];
    _saveFavorites();
  }

  void removeFavorite(String path) {
    // Don't remove system favorites
    if (state.any((fav) => fav.path == path && fav.isSystem)) return;

    state = state.where((fav) => fav.path != path).toList();
    _saveFavorites();
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

// Provide SharedPreferences instance to the favorites provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('You must override this provider before use');
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteDirectory>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});
