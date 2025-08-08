import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/events/base_event.dart';
import 'package:macos_file_manager/events/file_operation_event.dart';
import 'package:macos_file_manager/events/file_organization_event.dart';
import 'package:macos_file_manager/events/navigation_event.dart';
import 'package:macos_file_manager/state/base_state.dart';
import 'package:macos_file_manager/widgets/file_details.dart';
import 'package:macos_file_manager/widgets/sidebar_panel.dart';
import 'package:macos_file_manager/widgets/toolbar.dart';

class HomePage extends HookConsumerWidget
    with BaseState, BaseEvent, NavigationEvent, FileOperationEvent, FileOrganizationEvent {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() async {
        final desktopPath = await getDesktopPath();
        await navigateToDirectory(ref, desktopPath);
      });
      return null;
    }, const []);

    // currentDirectoryProvider.watch ensures details panel updates appropriately without forcing sidebar/tree rerenders

    return Scaffold(
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: Row(
              children: [
                // Sidebar (left)
                const SizedBox(width: 300, child: SidebarPanel()),
                // Divider
                Container(width: 1, color: Theme.of(context).dividerColor),
                // File details section (right side)
                Expanded(child: FileDetails()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
