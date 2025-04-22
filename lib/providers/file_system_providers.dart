import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:path/path.dart' as path;

// Provider for the list of file system items
final fileSystemItemListProvider = NotifierProvider<FileSystemItemList, List<FileSystemItem>>(FileSystemItemList.new);

// Provider for the current directory path
final currentDirectoryProvider = StateProvider<String>((ref) {
  return Directory.current.path;
});

// Provider for the selected file system item
final selectedFileItemProvider = StateProvider<FileSystemItem?>((ref) => null);

// Provider for the last selected path
final lastSelectedPathProvider = StateProvider<String?>((ref) => null);

// Provider for searching files in treeview
final searchQueryProvider = StateProvider<String?>((ref) => null);

// Provider for the count of selected items
final selectedItemsCountProvider = Provider<int>((ref) {
  final items = ref.watch(fileSystemItemListProvider);
  return items.where((item) => item.isSelected).length;
});

// Provider for the count of selected directories
final selectedDirectoriesCountProvider = Provider<int>((ref) {
  final items = ref.watch(fileSystemItemListProvider);
  return items.where((item) => item.isSelected && item.type == FileSystemItemType.directory).length;
});

// Provider for the count of selected files
final selectedFilesCountProvider = Provider<int>((ref) {
  final items = ref.watch(fileSystemItemListProvider);
  return items.where((item) => item.isSelected && item.type == FileSystemItemType.file).length;
});

// Provider for the directory history
final directoryHistoryProvider = StateNotifierProvider<DirectoryHistoryNotifier, DirectoryHistory>((ref) {
  return DirectoryHistoryNotifier();
});

// Class representing the directory history
class DirectoryHistory {
  final List<String> history;
  final int currentIndex;

  DirectoryHistory({required this.history, required this.currentIndex});

  bool get canGoBack => currentIndex > 0;
  bool get canGoForward => currentIndex < history.length - 1;
  bool get canGoUpperDir => currentPath != '/';
  String get currentPath => history[currentIndex];

  // Create a copy of the directory history with optional changes
  DirectoryHistory copyWith({List<String>? history, int? currentIndex}) {
    return DirectoryHistory(history: history ?? this.history, currentIndex: currentIndex ?? this.currentIndex);
  }
}

// State notifier for the directory history
class DirectoryHistoryNotifier extends StateNotifier<DirectoryHistory> {
  DirectoryHistoryNotifier() : super(DirectoryHistory(history: [Directory.current.path], currentIndex: 0));

  // Navigate to a new path
  void navigateTo(String path) {
    if (path == state.currentPath) return;
    final newHistory = state.history.sublist(0, state.currentIndex + 1);
    newHistory.add(path);
    state = state.copyWith(history: newHistory, currentIndex: newHistory.length - 1);
  }

  void goBack() {
    if (state.canGoBack) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goForward() {
    if (state.canGoForward) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void goUp() {
    final parent = path.dirname(state.currentPath);
    if (parent != state.currentPath) {
      navigateTo(parent);
    }
  }
}
