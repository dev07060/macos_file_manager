import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

class ArchiveUtils {
  /// Recursively adds a directory and its contents to an archive
  static Future<void> addDirectoryToArchive(
    Archive archive,
    String dirPath,
    String archivePath,
  ) async {
    final dir = Directory(dirPath);
    final entities = await dir.list(recursive: false).toList();

    for (final entity in entities) {
      final relativePath = path.join(archivePath, path.basename(entity.path));

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await addDirectoryToArchive(archive, entity.path, relativePath);
      }
    }
  }
}
