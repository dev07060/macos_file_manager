import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';

mixin class BaseState {
  ///
  /// Current directory path
  ///
  String currentDirectory(WidgetRef ref) => ref.watch(currentDirectoryProvider);

  ///
  /// List of file system items in the current directory
  ///
  List<FileSystemItem> fileSystemItems(WidgetRef ref) => ref.watch(fileSystemItemListProvider);

  ///
  /// Currently selected file item
  ///
  FileSystemItem? selectedFileItem(WidgetRef ref) => ref.watch(selectedFileItemProvider);

  ///
  /// Directory history
  ///
  DirectoryHistory directoryHistory(WidgetRef ref) => ref.watch(directoryHistoryProvider);
}
