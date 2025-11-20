import 'dart:developer' as developer;
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_organization_result.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/services/file_organization_service.dart';

/// 파일 분석 관련 이벤트를 처리하는 mixin
mixin class FileAnalysisEvent {
  /// 상세한 파일 분석 (키워드 매칭 정보 포함)
  Future<List<FileOrganizationResult>> analyzeFilesWithDetails(
    WidgetRef ref,
    List<FileSystemItem> fileSystemItems,
  ) async {
    final fileService = ref.read(fileOrganizationServiceProvider);
    final List<FileOrganizationResult> results = [];

    for (final item in fileSystemItems) {
      if (item.type == FileSystemItemType.file) {
        final snippet = await _readFileSnippet(item);
        final result = fileService.classifyFileWithDetails(item.path, item.name, snippet);
        results.add(result);
      }
    }

    return results;
  }

  Future<String> _readFileSnippet(FileSystemItem item) async {
    try {
      // 바이너리 파일 확장자 목록 (텍스트로 읽을 수 없는 파일들)
      const binaryExtensions = {
        // 이미지
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp', 'ico', 'svg',
        // 문서
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'hwp',
        // 압축
        'zip', 'rar', '7z', 'tar', 'gz', 'bz2',
        // 실행파일
        'exe', 'dmg', 'pkg', 'deb', 'rpm',
        // 미디어
        'mp3', 'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'wav', 'flac',
        // 기타 바이너리
        'bin', 'dat', 'db', 'sqlite', 'sqlite3',
      };

      final extension = item.fileExtension.toLowerCase().replaceFirst('.', '');

      // 바이너리 파일은 빈 문자열 반환
      if (binaryExtensions.contains(extension)) {
        return "";
      }

      final file = File(item.path);
      String snippet = await file.readAsString();

      if (snippet.length > 500) {
        snippet = snippet.substring(0, 500);
      }

      return snippet;
    } catch (e) {
      developer.log('Failed to read file snippet for ${item.name}: $e');
      return "";
    }
  }
}
