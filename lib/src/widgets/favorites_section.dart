import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/src/home_event.dart';

class FavoritesSection extends HookConsumerWidget with HomeEvent {
  const FavoritesSection({super.key});

  // 5개 항목의 최대 높이 계산 (각 항목 높이 40 + 상하 패딩 16)
  static const double _maxCollapsedHeight = 216; // (40 * 5 + 16)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final currentDirectory = ref.watch(currentDirectoryProvider);

    // 확장/축소 상태 관리
    final isExpanded = useState(true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 섹션
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
              // 확장/축소 아이콘 버튼
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

        // 확장/축소 가능한 즐겨찾기 목록
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
                // 항목이 5개 이상일 때만 스크롤 가능하게 설정
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
                            // 현재 위치 배지
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
