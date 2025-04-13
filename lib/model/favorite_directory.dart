import 'package:flutter/foundation.dart' show immutable;

@immutable
class FavoriteDirectory {
  const FavoriteDirectory({
    required this.path,
    required this.name,
    required this.isSystem, // To identify system defaults like Desktop, Documents, etc.
  });

  final String path;
  final String name;
  final bool isSystem;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteDirectory && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
