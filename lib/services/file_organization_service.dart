import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;

// 정리 방식 열거형
enum OrganizationMethod {
  category, // 카테고리별 정리
  date, // 날짜별 정리
  fileType, // 파일 타입별 정리
  size, // 크기별 정리
  project, // 프로젝트별 정리
  custom, // 사용자 정의 정리
}

// 정리 방식 정보 클래스
class OrganizationMethodInfo {
  final OrganizationMethod method;
  final String displayName;
  final String description;
  final String icon;

  const OrganizationMethodInfo({
    required this.method,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}

class FileOrganizationService {
  // 정리 방식 목록
  static const List<OrganizationMethodInfo> organizationMethods = [
    OrganizationMethodInfo(
      method: OrganizationMethod.category,
      displayName: '카테고리별 정리',
      description: '파일 내용을 분석하여 카테고리별로 정리합니다',
      icon: '📁',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.date,
      displayName: '날짜별 정리',
      description: '파일 생성 날짜나 수정 날짜를 기준으로 정리합니다',
      icon: '📅',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.fileType,
      displayName: '파일 타입별 정리',
      description: '파일 확장자를 기준으로 정리합니다',
      icon: '📄',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.size,
      displayName: '크기별 정리',
      description: '파일 크기를 기준으로 정리합니다',
      icon: '📏',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.project,
      displayName: '프로젝트별 정리',
      description: '파일 내용을 분석하여 프로젝트별로 정리합니다',
      icon: '🚀',
    ),
    OrganizationMethodInfo(
      method: OrganizationMethod.custom,
      displayName: '사용자 정의 정리',
      description: '사용자가 정의한 규칙에 따라 정리합니다',
      icon: '⚙️',
    ),
  ];

  // 파일 확장자별 카테고리 매핑
  static const Map<String, String> _extensionCategories = {
    // 문서
    'pdf': '문서',
    'doc': '문서',
    'docx': '문서',
    'txt': '문서',
    'rtf': '문서',
    'odt': '문서',
    'pages': '문서',

    // 스프레드시트
    'xls': '문서',
    'xlsx': '문서',
    'csv': '문서',
    'numbers': '문서',

    // 프레젠테이션
    'ppt': '프레젠테이션',
    'pptx': '프레젠테이션',
    'key': '프레젠테이션',

    // 이미지
    'jpg': '이미지',
    'jpeg': '이미지',
    'png': '이미지',
    'gif': '이미지',
    'bmp': '이미지',
    'tiff': '이미지',
    'svg': '이미지',
    'webp': '이미지',
    'heic': '이미지',

    // 동영상
    'mp4': '동영상',
    'avi': '동영상',
    'mov': '동영상',
    'wmv': '동영상',
    'flv': '동영상',
    'mkv': '동영상',
    'webm': '동영상',
    'm4v': '동영상',

    // 음악
    'mp3': '음악',
    'wav': '음악',
    'flac': '음악',
    'aac': '음악',
    'm4a': '음악',
    'ogg': '음악',
    'wma': '음악',

    // 소스코드
    'dart': '소스코드',
    'js': '소스코드',
    'ts': '소스코드',
    'py': '소스코드',
    'java': '소스코드',
    'cpp': '소스코드',
    'c': '소스코드',
    'h': '소스코드',
    'swift': '소스코드',
    'kt': '소스코드',
    'go': '소스코드',
    'rs': '소스코드',
    'php': '소스코드',
    'rb': '소스코드',
    'html': '소스코드',
    'css': '소스코드',
    'scss': '소스코드',
    'json': '소스코드',
    'xml': '소스코드',
    'yaml': '소스코드',
    'yml': '소스코드',

    // 압축파일
    'zip': '압축파일',
    'rar': '압축파일',
    '7z': '압축파일',
    'tar': '압축파일',
    'gz': '압축파일',
    'bz2': '압축파일',

    // 실행파일
    'exe': '실행파일',
    'app': '실행파일',
    'dmg': '실행파일',
    'pkg': '실행파일',
    'deb': '실행파일',
    'rpm': '실행파일',
  };

  // 파일명 패턴별 카테고리 매핑
  static const Map<String, String> _filenamePatterns = {
    'invoice': '청구서',
    'bill': '청구서',
    '청구서': '청구서',
    '계산서': '청구서',

    'contract': '계약서',
    '계약서': '계약서',
    '약정서': '계약서',

    'report': '보고서',
    '보고서': '보고서',
    '리포트': '보고서',

    'presentation': '프레젠테이션',
    '발표': '프레젠테이션',
    '프레젠테이션': '프레젠테이션',
  };

  // 기존 메서드 - 카테고리별 분류
  String classifyFile(String fileName, String contentSnippet) {
    return _categorizeByContent(fileName, contentSnippet);
  }

  // 새로운 메서드 - 다양한 정리 방식 지원
  String organizeFile(
    String fileName,
    String contentSnippet,
    OrganizationMethod method, {
    String? customRule,
    Map<String, dynamic>? fileMetadata,
  }) {
    switch (method) {
      case OrganizationMethod.category:
        return _categorizeByContent(fileName, contentSnippet);
      case OrganizationMethod.date:
        return _categorizeByDate(fileName, fileMetadata);
      case OrganizationMethod.fileType:
        return _categorizeByFileType(fileName);
      case OrganizationMethod.size:
        return _categorizeBySize(fileMetadata);
      case OrganizationMethod.project:
        return _categorizeByProject(fileName, contentSnippet);
      case OrganizationMethod.custom:
        return _categorizeByCustomRule(fileName, contentSnippet, customRule);
    }
  }

  // 카테고리별 분류 로직
  String _categorizeByContent(String fileName, String contentSnippet) {
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = contentSnippet.toLowerCase();

    // 파일명 패턴 검사
    for (final entry in _filenamePatterns.entries) {
      if (lowerFileName.contains(entry.key) || lowerContent.contains(entry.key)) {
        return entry.value;
      }
    }

    // 확장자 기반 분류
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    if (_extensionCategories.containsKey(extension)) {
      return _extensionCategories[extension]!;
    }

    // 내용 기반 추가 분류
    if (lowerContent.contains('import') && lowerContent.contains('class')) {
      return '소스코드';
    }
    if (lowerContent.contains('invoice') || lowerContent.contains('bill')) {
      return '청구서';
    }
    if (lowerContent.contains('contract') || lowerContent.contains('agreement')) {
      return '계약서';
    }

    return '기타';
  }

  // 날짜별 분류 로직
  String _categorizeByDate(String fileName, Map<String, dynamic>? metadata) {
    final fileDate = metadata?['creationDate'] ?? metadata?['modificationDate'] ?? DateTime.now();
    final dateTime = fileDate is DateTime ? fileDate : DateTime.tryParse(fileDate.toString()) ?? DateTime.now();

    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    if (difference <= 7) {
      return '최근 1주일';
    } else if (difference <= 30) {
      return '최근 1개월';
    } else if (difference <= 90) {
      return '최근 3개월';
    } else if (dateTime.year == now.year) {
      return '${dateTime.year}년 ${dateTime.month}월';
    } else {
      return '${dateTime.year}년';
    }
  }

  // 파일 타입별 분류 로직
  String _categorizeByFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');

    if (_extensionCategories.containsKey(extension)) {
      return _extensionCategories[extension]!;
    }

    // 확장자가 없는 경우 파일명으로 추정
    if (extension.isEmpty) {
      final lowerFileName = fileName.toLowerCase();
      if (lowerFileName.contains('readme') || lowerFileName.contains('license')) {
        return '문서';
      }
      if (lowerFileName.contains('makefile') || lowerFileName.contains('dockerfile')) {
        return '소스코드';
      }
    }

    return '기타';
  }

  // 크기별 분류 로직
  String _categorizeBySize(Map<String, dynamic>? metadata) {
    final fileSize = metadata?['size'] ?? 0;
    final sizeInBytes = fileSize as num;

    if (sizeInBytes < 1024 * 1024) {
      // 1MB 미만
      return '소용량 (1MB 미만)';
    } else if (sizeInBytes < 10 * 1024 * 1024) {
      // 10MB 미만
      return '중용량 (1MB-10MB)';
    } else if (sizeInBytes < 100 * 1024 * 1024) {
      // 100MB 미만
      return '대용량 (10MB-100MB)';
    } else {
      return '초대용량 (100MB 이상)';
    }
  }

  // 프로젝트별 분류 로직
  String _categorizeByProject(String fileName, String contentSnippet) {
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = contentSnippet.toLowerCase();

    // Flutter/Dart 프로젝트
    if (lowerFileName.contains('.dart') || lowerContent.contains('flutter') || lowerContent.contains('dart')) {
      return 'Flutter 앱 개발';
    }

    // 웹 개발
    if (lowerFileName.contains('.html') ||
        lowerFileName.contains('.css') ||
        lowerFileName.contains('.js') ||
        lowerContent.contains('html') ||
        lowerContent.contains('css') ||
        lowerContent.contains('javascript')) {
      return '웹사이트 개발';
    }

    // 디자인 파일
    if (lowerFileName.contains('design') ||
        lowerFileName.contains('ui') ||
        lowerFileName.contains('mockup') ||
        lowerContent.contains('design') ||
        lowerContent.contains('mockup')) {
      return '디자인 프로젝트';
    }

    // 재무 관련
    if (lowerFileName.contains('finance') ||
        lowerFileName.contains('budget') ||
        lowerFileName.contains('invoice') ||
        lowerContent.contains('finance') ||
        lowerContent.contains('budget')) {
      return '재무 관리';
    }

    // 마케팅 관련
    if (lowerFileName.contains('marketing') ||
        lowerFileName.contains('campaign') ||
        lowerFileName.contains('ad') ||
        lowerContent.contains('marketing') ||
        lowerContent.contains('campaign')) {
      return '마케팅 자료';
    }

    // 개인 사진/동영상
    final extension = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'].contains(extension)) {
      if (lowerFileName.contains('photo') || lowerFileName.contains('pic') || lowerFileName.contains('img')) {
        return '개인 사진';
      }
      if (lowerFileName.contains('video') || lowerFileName.contains('movie')) {
        return '개인 동영상';
      }
    }

    return '일반 프로젝트';
  }

  // 사용자 정의 규칙 분류 로직
  String _categorizeByCustomRule(String fileName, String contentSnippet, String? customRule) {
    if (customRule == null || customRule.isEmpty) {
      return _categorizeByContent(fileName, contentSnippet);
    }

    // 간단한 키워드 기반 규칙 처리
    final rules = customRule.split(',').map((e) => e.trim()).toList();
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = contentSnippet.toLowerCase();

    for (final rule in rules) {
      if (rule.contains(':')) {
        final parts = rule.split(':');
        if (parts.length == 2) {
          final keyword = parts[0].trim().toLowerCase();
          final category = parts[1].trim();

          if (lowerFileName.contains(keyword) || lowerContent.contains(keyword)) {
            return category;
          }
        }
      }
    }

    return '사용자 정의';
  }
}

final fileOrganizationServiceProvider = Provider<FileOrganizationService>((ref) {
  return FileOrganizationService();
});
