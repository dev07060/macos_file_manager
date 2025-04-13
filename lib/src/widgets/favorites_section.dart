import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/src/home_event.dart';

class FavoritesSection extends HookConsumerWidget with HomeEvent {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer()],
          ),
        ),
        if (favorites.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No favorites', style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => navigateToDirectory(ref, favorite.path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(child: Text(favorite.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const Divider(height: 1),
      ],
    );
  }
}
