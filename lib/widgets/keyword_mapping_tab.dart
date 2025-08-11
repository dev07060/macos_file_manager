import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';
import 'package:macos_file_manager/widgets/dialogs/add_keyword_dialog.dart';

/// 키워드 매핑 관리를 위한 탭 위젯
class KeywordMappingTab extends ConsumerStatefulWidget {
  const KeywordMappingTab({super.key});

  @override
  ConsumerState<KeywordMappingTab> createState() => _KeywordMappingTabState();
}

class _KeywordMappingTabState extends ConsumerState<KeywordMappingTab> {
  String _searchQuery = '';
  String _sortBy = 'priority'; // priority, pattern, category, type
  bool _sortAscending = true;
  String _filterType = 'all'; // all, regex, text, custom

  @override
  Widget build(BuildContext context) {
    final mappings = ref.watch(sortedKeywordMappingsProvider);
    final filteredAndSortedMappings = _getFilteredAndSortedMappings(mappings);

    return Column(
      children: [
        // 헤더와 컨트롤
        _buildHeader(mappings.length),

        // 검색 및 필터 바
        _buildSearchAndFilterBar(),

        // 테이블 헤더
        _buildTableHeader(),

        // 테이블 내용 (드래그 앤 드롭 지원)
        Expanded(child: _buildDraggableTable(filteredAndSortedMappings)),
      ],
    );
  }

  /// 헤더 위젯 빌드
  Widget _buildHeader(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            '키워드 매핑 ($totalCount개)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddKeywordDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('키워드 추가'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          ),
        ],
      ),
    );
  }

  /// 검색 및 필터 바 빌드
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .3))),
      ),
      child: Row(
        children: [
          // 검색 필드
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '패턴 또는 카테고리 검색...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          const SizedBox(width: 12),

          // 타입 필터
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: '타입 필터',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('전체')),
                DropdownMenuItem(value: 'regex', child: Text('정규식')),
                DropdownMenuItem(value: 'text', child: Text('텍스트')),
                DropdownMenuItem(value: 'custom', child: Text('사용자 정의')),
              ],
              onChanged: (value) => setState(() => _filterType = value ?? 'all'),
            ),
          ),

          const SizedBox(width: 12),

          // 정렬 기준
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: '정렬 기준',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'priority', child: Text('우선순위')),
                DropdownMenuItem(value: 'pattern', child: Text('패턴')),
                DropdownMenuItem(value: 'category', child: Text('카테고리')),
                DropdownMenuItem(value: 'type', child: Text('타입')),
              ],
              onChanged: (value) => setState(() => _sortBy = value ?? 'priority'),
            ),
          ),

          const SizedBox(width: 8),

          // 정렬 방향 토글
          IconButton(
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortAscending ? '오름차순' : '내림차순',
          ),
        ],
      ),
    );
  }

  /// 테이블 헤더 빌드
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24), // 드래그 핸들 공간
          const SizedBox(width: 60, child: Text('우선순위', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 200, child: Text('패턴', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 150, child: Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 80, child: Text('타입', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 80, child: Text('대소문자', style: TextStyle(fontWeight: FontWeight.bold))),
          const Spacer(),
          const SizedBox(width: 120, child: Text('작업', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  /// 드래그 가능한 테이블 빌드
  Widget _buildDraggableTable(List<KeywordMapping> mappings) {
    if (mappings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterType != 'all'
                  ? '검색 조건에 맞는 키워드 매핑이 없습니다.'
                  : '키워드 매핑이 없습니다.\n"키워드 추가" 버튼을 클릭하여 새 매핑을 추가하세요.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      onReorder: _onReorder,
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final mapping = mappings[index];
        return _buildMappingRow(mapping, index, key: ValueKey(mapping.pattern));
      },
    );
  }

  /// 매핑 행 빌드
  Widget _buildMappingRow(KeywordMapping mapping, int index, {required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .3))),
        color: index % 2 == 0 ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .1),
      ),
      child: Row(
        children: [
          // 드래그 핸들
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 4),

          // 우선순위
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .3)),
              ),
              child: Text(
                '${mapping.priority}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // 패턴
          SizedBox(
            width: 200,
            child: Text(
              mapping.pattern,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 카테고리
          SizedBox(width: 150, child: Text(mapping.category, overflow: TextOverflow.ellipsis)),

          // 타입 (정규식/텍스트)
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: mapping.isRegex ? Colors.orange.withValues(alpha: .1) : Colors.green.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: mapping.isRegex ? Colors.orange.withValues(alpha: .3) : Colors.green.withValues(alpha: .3),
                ),
              ),
              child: Text(
                mapping.isRegex ? '정규식' : '텍스트',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: mapping.isRegex ? Colors.orange[700] : Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 대소문자 구분
          SizedBox(
            width: 80,
            child: Icon(
              mapping.caseSensitive ? Icons.text_fields : Icons.text_format,
              size: 16,
              color: mapping.caseSensitive ? Colors.red : Colors.grey,
            ),
          ),

          const Spacer(),

          // 작업 버튼들
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 테스트 버튼
                IconButton(
                  onPressed: () => _showTestPatternDialog(mapping),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  tooltip: '패턴 테스트',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

                // 편집 버튼
                IconButton(
                  onPressed: () => _showEditKeywordDialog(mapping),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: AppStrings.edit,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

                // 삭제 버튼 (사용자 정의만)
                if (mapping.isCustom)
                  IconButton(
                    onPressed: () => _removeKeywordMapping(mapping.pattern),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    tooltip: AppStrings.delete,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 필터링 및 정렬된 매핑 리스트 반환
  List<KeywordMapping> _getFilteredAndSortedMappings(List<KeywordMapping> mappings) {
    var filtered =
        mappings.where((mapping) {
          // 검색 필터
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            if (!mapping.pattern.toLowerCase().contains(query) && !mapping.category.toLowerCase().contains(query)) {
              return false;
            }
          }

          // 타입 필터
          switch (_filterType) {
            case 'regex':
              return mapping.isRegex;
            case 'text':
              return !mapping.isRegex;
            case 'custom':
              return mapping.isCustom;
            default:
              return true;
          }
        }).toList();

    // 정렬
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'pattern':
          comparison = a.pattern.compareTo(b.pattern);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'type':
          comparison = (a.isRegex ? 1 : 0).compareTo(b.isRegex ? 1 : 0);
          break;
        case 'priority':
        default:
          comparison = a.priority.compareTo(b.priority);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  /// 드래그 앤 드롭으로 순서 변경
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final mappings = ref.read(sortedKeywordMappingsProvider);
    final filteredMappings = _getFilteredAndSortedMappings(mappings);

    if (oldIndex >= filteredMappings.length || newIndex >= filteredMappings.length) {
      return;
    }

    // 우선순위 재계산
    final updatedMappings = <KeywordMapping>[];

    for (int i = 0; i < filteredMappings.length; i++) {
      final mapping = filteredMappings[i];
      int newPriority;

      if (i == newIndex) {
        // 이동된 항목
        newPriority = newIndex;
        updatedMappings.add(filteredMappings[oldIndex].copyWith(priority: newPriority));
      } else if (i == oldIndex) {
        // 원래 위치의 항목은 건너뛰기
        continue;
      } else {
        // 다른 항목들의 우선순위 조정
        if (oldIndex < newIndex) {
          // 아래로 이동: oldIndex+1 ~ newIndex 범위의 항목들을 위로 이동
          if (i > oldIndex && i <= newIndex) {
            newPriority = i - 1;
          } else {
            newPriority = i;
          }
        } else {
          // 위로 이동: newIndex ~ oldIndex-1 범위의 항목들을 아래로 이동
          if (i >= newIndex && i < oldIndex) {
            newPriority = i + 1;
          } else {
            newPriority = i;
          }
        }
        updatedMappings.add(mapping.copyWith(priority: newPriority));
      }
    }

    // 변경사항 저장
    ref.read(fileCategoryConfigProvider.notifier).updateKeywordMappingPriorities(updatedMappings);
  }

  /// 키워드 추가 다이얼로그 표시
  void _showAddKeywordDialog() {
    final categories = ref.read(availableCategoriesProvider);
    final existingMappings = ref.read(sortedKeywordMappingsProvider);

    showDialog(
      context: context,
      builder: (context) => AddKeywordDialog(categories: categories, existingMappings: existingMappings),
    ).then((result) {
      if (result != null && result is KeywordMapping) {
        ref.read(fileCategoryConfigProvider.notifier).addKeywordMapping(result);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('키워드 매핑 "${result.pattern}"이(가) 추가되었습니다.')));
      }
    });
  }

  /// 키워드 편집 다이얼로그 표시
  void _showEditKeywordDialog(KeywordMapping mapping) {
    // TODO: EditKeywordDialog 구현 후 연결
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('키워드 편집 다이얼로그는 다음 작업에서 구현됩니다.')));
  }

  /// 패턴 테스트 다이얼로그 표시
  void _showTestPatternDialog(KeywordMapping mapping) {
    showDialog(context: context, builder: (context) => _PatternTestDialog(mapping: mapping));
  }

  /// 키워드 매핑 제거
  void _removeKeywordMapping(String pattern) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('키워드 매핑 삭제'),
            content: Text('패턴 "$pattern"을(를) 삭제하시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
              TextButton(
                onPressed: () {
                  ref.read(fileCategoryConfigProvider.notifier).removeKeywordMapping(pattern);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('키워드 매핑 "$pattern"이(가) 삭제되었습니다.')));
                },
                child: const Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

/// 패턴 테스트 다이얼로그
class _PatternTestDialog extends ConsumerStatefulWidget {
  final KeywordMapping mapping;

  const _PatternTestDialog({required this.mapping});

  @override
  ConsumerState<_PatternTestDialog> createState() => _PatternTestDialogState();
}

class _PatternTestDialogState extends ConsumerState<_PatternTestDialog> {
  final _testController = TextEditingController();
  bool? _testResult;
  String? _errorMessage;

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('패턴 테스트'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 매핑 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('패턴: ${widget.mapping.pattern}', style: const TextStyle(fontFamily: 'monospace')),
                  Text('타입: ${widget.mapping.isRegex ? '정규식' : '텍스트'}'),
                  Text('대소문자 구분: ${widget.mapping.caseSensitive ? '예' : '아니오'}'),
                  Text('카테고리: ${widget.mapping.category}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 테스트 입력
            TextField(
              controller: _testController,
              decoration: const InputDecoration(
                labelText: '테스트할 파일명',
                hintText: 'example_file.txt',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _testPattern(),
            ),

            const SizedBox(height: 16),

            // 결과 표시
            if (_testResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult! ? Colors.green.withValues(alpha: .1) : Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult! ? Colors.green.withValues(alpha: .3) : Colors.red.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult! ? Icons.check_circle : Icons.cancel,
                      color: _testResult! ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult! ? '매치됨' : '매치되지 않음',
                        style: TextStyle(
                          color: _testResult! ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 오류 메시지
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: .3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700]))),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.close))],
    );
  }

  void _testPattern() {
    final fileName = _testController.text.trim();
    if (fileName.isEmpty) {
      setState(() {
        _testResult = null;
        _errorMessage = null;
      });
      return;
    }

    try {
      final result = ref.read(fileCategoryConfigProvider.notifier).testKeywordPattern(fileName, widget.mapping);
      setState(() {
        _testResult = result;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _testResult = null;
        _errorMessage = '패턴 테스트 중 오류 발생: $e';
      });
    }
  }
}
