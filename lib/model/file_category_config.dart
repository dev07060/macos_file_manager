/// 파일 카테고리 설정을 관리하는 모델
class FileCategoryConfig {
  final Map<String, String> extensionCategories;

  const FileCategoryConfig({this.extensionCategories = const {}});

  /// 기본 설정을 반환
  factory FileCategoryConfig.defaultConfig() {
    return const FileCategoryConfig(
      extensionCategories: {
        // 문서
        'pdf': '문서',
        'doc': '문서',
        'docx': '문서',
        'txt': '문서',
        'rtf': '문서',
        'odt': '문서',
        'pages': '문서',
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
      },
    );
  }

  /// copyWith 메서드
  FileCategoryConfig copyWith({Map<String, String>? extensionCategories}) {
    return FileCategoryConfig(extensionCategories: extensionCategories ?? this.extensionCategories);
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'extensionCategories': extensionCategories};
  }

  /// JSON에서 생성
  factory FileCategoryConfig.fromJson(Map<String, dynamic> json) {
    return FileCategoryConfig(extensionCategories: Map<String, String>.from(json['extensionCategories'] ?? {}));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileCategoryConfig && _mapEquals(extensionCategories, other.extensionCategories);
  }

  @override
  int get hashCode => extensionCategories.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}

/// 개별 확장자 매핑 항목
class ExtensionMapping {
  final String extension;
  final String category;
  final bool isCustom;

  const ExtensionMapping({required this.extension, required this.category, this.isCustom = false});

  /// copyWith 메서드
  ExtensionMapping copyWith({String? extension, String? category, bool? isCustom}) {
    return ExtensionMapping(
      extension: extension ?? this.extension,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'extension': extension, 'category': category, 'isCustom': isCustom};
  }

  /// JSON에서 생성
  factory ExtensionMapping.fromJson(Map<String, dynamic> json) {
    return ExtensionMapping(
      extension: json['extension'] as String,
      category: json['category'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtensionMapping &&
        other.extension == extension &&
        other.category == category &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => extension.hashCode ^ category.hashCode ^ isCustom.hashCode;
}
