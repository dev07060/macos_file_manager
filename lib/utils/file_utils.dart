import 'dart:io';

import 'package:macos_file_manager/constants/file_constants.dart';
import 'package:macos_file_manager/model/file_system_item.dart';

class FileUtils {
  static String formatDate(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time = '${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
    return '$date $time';
  }

  static String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  static String getParentPath(String filePath) {
    final lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator <= 0) return filePath;
    return filePath.substring(0, lastSeparator);
  }

  static bool isImageFile(FileSystemItem item) {
    if (item.type == FileSystemItemType.file) {
      final extension = item.fileExtension.toLowerCase();
      return FileConstants.imageExtensions.contains(extension);
    }
    return false;
  }

  static bool isShellScript(FileSystemItem item) {
    if (item.type == FileSystemItemType.file) {
      final extension = item.fileExtension.toLowerCase();
      return extension == FileConstants.shellScriptExtension;
    }
    return false;
  }
}
