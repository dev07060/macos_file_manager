import 'dart:developer' as developer;
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/services/vertex_ai_service.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

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

// 파일 정리 설정 provider 추가
final fileOrganizationSettingsProvider =
    StateNotifierProvider<FileOrganizationSettingsNotifier, FileOrganizationSettings>((ref) {
      return FileOrganizationSettingsNotifier();
    });

class FileOrganizationSettings {
  final OrganizationMethod? preferredMethod;
  final String? lastCustomPrompt;
  final bool rememberChoice;

  const FileOrganizationSettings({this.preferredMethod, this.lastCustomPrompt, this.rememberChoice = false});

  FileOrganizationSettings copyWith({
    OrganizationMethod? preferredMethod,
    String? lastCustomPrompt,
    bool? rememberChoice,
  }) {
    return FileOrganizationSettings(
      preferredMethod: preferredMethod ?? this.preferredMethod,
      lastCustomPrompt: lastCustomPrompt ?? this.lastCustomPrompt,
      rememberChoice: rememberChoice ?? this.rememberChoice,
    );
  }
}

class FileOrganizationSettingsNotifier extends StateNotifier<FileOrganizationSettings> {
  FileOrganizationSettingsNotifier() : super(const FileOrganizationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methodIndex = prefs.getInt('preferred_organization_method');
      final lastCustomPrompt = prefs.getString('last_custom_prompt');
      final rememberChoice = prefs.getBool('remember_organization_choice') ?? false;

      state = FileOrganizationSettings(
        preferredMethod: methodIndex != null ? OrganizationMethod.values[methodIndex] : null,
        lastCustomPrompt: lastCustomPrompt,
        rememberChoice: rememberChoice,
      );
    } catch (e) {
      developer.log('Error loading organization settings: $e');
    }
  }

  Future<void> savePreferredMethod(OrganizationMethod method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('preferred_organization_method', method.index);

      state = state.copyWith(preferredMethod: method);
    } catch (e) {
      developer.log('Error saving preferred method: $e');
    }
  }

  Future<void> saveCustomPrompt(String prompt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_custom_prompt', prompt);

      state = state.copyWith(lastCustomPrompt: prompt);
    } catch (e) {
      developer.log('Error saving custom prompt: $e');
    }
  }

  Future<void> setRememberChoice(bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_organization_choice', remember);

      state = state.copyWith(rememberChoice: remember);
    } catch (e) {
      developer.log('Error saving remember choice: $e');
    }
  }

  void clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('preferred_organization_method');
      await prefs.remove('last_custom_prompt');
      await prefs.remove('remember_organization_choice');

      state = const FileOrganizationSettings();
    } catch (e) {
      developer.log('Error clearing settings: $e');
    }
  }
}
