import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:path/path.dart' as path;

final fileSystemItemListProvider = NotifierProvider<FileSystemItemList, List<FileSystemItem>>(FileSystemItemList.new);

final currentDirectoryProvider = StateProvider<String>((ref) {
  return Directory.current.path;
});

final selectedFileItemProvider = StateProvider<FileSystemItem?>((ref) => null);

final lastSelectedPathProvider = StateProvider<String?>((ref) => null);

final selectedItemsCountProvider = Provider<int>((ref) {
  final items = ref.watch(fileSystemItemListProvider);
  return items.where((item) => item.isSelected).length;
});

final selectedDirectoriesCountProvider = Provider<int>((ref) {
  final items = ref.watch(fileSystemItemListProvider);
  return items.where((item) => item.isSelected && item.type == FileSystemItemType.directory).length;
});

final selectedFilesCountProvider = Provider<int>((ref) {
  final items = ref.watch(fileSystemItemListProvider);
  return items.where((item) => item.isSelected && item.type == FileSystemItemType.file).length;
});

final directoryHistoryProvider = StateNotifierProvider<DirectoryHistoryNotifier, DirectoryHistory>((ref) {
  return DirectoryHistoryNotifier();
});

class DirectoryHistory {
  final List<String> history;
  final int currentIndex;

  DirectoryHistory({required this.history, required this.currentIndex});

  bool get canGoBack => currentIndex > 0;
  bool get canGoForward => currentIndex < history.length - 1;

  String get currentPath => history[currentIndex];

  DirectoryHistory copyWith({List<String>? history, int? currentIndex}) {
    return DirectoryHistory(history: history ?? this.history, currentIndex: currentIndex ?? this.currentIndex);
  }
}

class DirectoryHistoryNotifier extends StateNotifier<DirectoryHistory> {
  DirectoryHistoryNotifier() : super(DirectoryHistory(history: [Directory.current.path], currentIndex: 0));

  void navigateTo(String path) {
    if (path == state.currentPath) return;

    // If we're not at the end of the history, truncate it
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
