import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';

class SearchResultList extends ConsumerWidget {
  final List<DirectoryNodeData> matches;
  final Function(DirectoryNodeData) onSelect;

  const SearchResultList({super.key, required this.matches, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final node = matches[index];
        return ListTile(title: Text(node.name), onTap: () => onSelect(node));
      },
    );
  }
}
