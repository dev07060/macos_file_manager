import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../model/file_system_item.dart';

// Provider for the list of file system items
final fileSystemItemListProvider = NotifierProvider<FileSystemItemList, List<FileSystemItem>>(FileSystemItemList.new);

// Provider for the current directory path
final currentDirectoryProvider = StateProvider<String>((ref) {
  // Start with the user's home directory
  return Directory.current.path;
});

// Provider for the currently selected file system item
final selectedFileItemProvider = StateProvider<FileSystemItem?>((ref) => null);

// Provider to track the path history for navigation
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
