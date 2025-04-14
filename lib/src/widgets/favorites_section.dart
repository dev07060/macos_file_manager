import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/src/home_event.dart';

class FavoritesSection extends HookConsumerWidget with HomeEvent {
  const FavoritesSection({super.key});

  static const double _maxCollapsedHeight = 216; // (40 * 5 + 16)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final currentDirectory = ref.watch(currentDirectoryProvider);

    final isExpanded = useState(true);

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
            children: [
              const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: Icon(isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No favorites', style: TextStyle(color: Colors.grey)),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: _maxCollapsedHeight),
              child: ListView.builder(
                shrinkWrap: true,
                physics:
                    favorites.length > 5 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final favorite = favorites[index];
                  final isCurrentLocation = favorite.path == currentDirectory;

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
                            if (isCurrentLocation)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'current location',
                                  style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        const Divider(height: 1),
      ],
    );
  }
}
