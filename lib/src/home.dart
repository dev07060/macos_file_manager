import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'home_event.dart';
import 'home_state.dart';
import '../model/file_system_item.dart';

part 'widgets/toolbar.dart';
part 'widgets/file_item.dart';
part 'widgets/file_details.dart';

class HomePage extends HookConsumerWidget with HomeState, HomeEvent {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the home directory when the page is first built
    useEffect(() {
      Future.microtask(() async {
        // Default to home directory or root if home isn't available
        final homePath = Platform.environment['HOME'] ?? '/';
        await navigateToDirectory(ref, homePath);
      });
      return null;
    }, const []);

    final items = fileSystemItems(ref);

    return Scaffold(
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: Row(
              children: [
                // File/Folder list section (left side)
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: const Row(children: [Text('Name', style: TextStyle(fontWeight: FontWeight.bold))]),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return FileItem(item: items[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(width: 1, color: Colors.grey.shade300),
                // File details section (right side)
                const Expanded(child: FileDetails()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
