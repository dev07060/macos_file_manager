import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:path/path.dart' as path;

mixin class FavoriteEvent {
  /// Toggle favorite directory (add or remove)
  Future<void> toggleFavoriteDirectory(WidgetRef ref, String directoryPath) async {
    final directoryName = path.basename(directoryPath);
    ref.read(favoritesProvider.notifier).toggleFavorite(directoryPath, directoryName);
  }
}
