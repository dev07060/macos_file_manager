class AppStrings {
  // Common
  static const String cancel = '취소';
  static const String confirm = '확인';
  static const String close = '닫기';
  static const String complete = '완료';
  static const String reset = '리셋';
  static const String add = '추가';
  static const String edit = '수정';
  static const String delete = '삭제';
  static const String save = '저장';
  static const String run = '실행';
  static const String error = '오류';

  // File Operations
  static const String deleteSelectedItems = '선택한 항목 삭제';
  static const String compressSelectedItems = '선택한 항목 압축';
  static const String organizeWithAI = 'AI로 파일 정리';
  static const String fileCategorySettings = '파일 확장자 설정';
  static const String showTreeView = '디렉토리 트리 보기';
  static const String rename = '이름 바꾸기';
  static const String overwrite = '덮어쓰기';
  static const String compress = '압축';
  static const String compressing = '압축 중...';
  static const String createArchiveTitle = '압축 파일 생성';
  static const String archiveFileNameLabel = '압축 파일 이름';
  static const String compressError = '압축 중 오류가 발생했습니다:';
  static const String renameFailed = '파일 이름 변경에 실패했습니다.';

  // Dialogs
  static const String resetSettingsTitle = '설정 리셋';
  static const String resetSettingsMessage = '모든 설정을 기본값으로 되돌리시겠습니까?';
  static const String settingsResetMessage = '설정이 기본값으로 리셋되었습니다.';
  static const String exportSettings = '설정 내보내기';
  static const String importSettings = '설정 가져오기';
  static const String settingsExportedMessage = '설정이 클립보드에 복사되었습니다.';
  static const String importSettingsTitle = '설정 가져오기';
  static const String importSettingsHint = '내보낸 설정 JSON을 붙여넣으세요';
  static const String settingsImportedMessage = '설정을 성공적으로 가져왔습니다.';
  static const String settingsImportFailedMessage = '설정 가져오기에 실패했습니다.';
  static const String addExtensionTitle = '확장자 추가';
  static const String extensionLabel = '확장자';
  static const String extensionHint = 'pdf, jpg, txt 등 (점 제외)';
  static const String categoryLabel = '카테고리';
  static const String editExtensionTitle = '확장자 수정:';

  // File Details
  static const String noFileSelected = '선택된 파일 없음';
  static const String preview = '미리보기';
  static const String runSh = 'Run .sh';
  static const String imageSavedMessage = '이미지가 성공적으로 저장되었습니다.';
  static const String imageCroppedMessage = '이미지가 잘리고 성공적으로 저장되었습니다.';

  // Favorites
  static const String favorites = '즐겨찾기';
  static const String noFavorites = '즐겨찾기 없음';
  static const String currentLocation = '현재 위치';
  static const String collapse = '접기';
  static const String expand = '펴기';

  // Tree View
  static const String searchHint = '트리 내에서 디렉토리 이름을 검색할 수 있습니다.';
  static const String noResultsFound = '검색 결과 없음';
  static const String noDirectoryStructure = '디렉토리 구조 없음';
  static const String errorLoadingTree = '트리를 불러오는 중 오류 발생:';
  static const String retry = '재시도';
  static const String goBack = '뒤로 가기';
  static const String viewLess = '[view less]';
  static const String viewMore = '[view more]';

  // File Organization
  static const String fileOrganizationProposal = '파일 정리 제안';
  static const String fileOrganizationComplete = '파일 정리 완료';
  static const String fileOrganizationCompleteMessage = '파일 정리가 완료되었습니다.';
  static const String undo = '되돌리기';
  static const String keep = '유지하기';
  static const String fileOrganizationKept = '파일 정리가 유지됩니다.';
  static const String fileOrganizationUndone = '파일 위치를 되돌렸습니다.';
  static const String noFilesToOrganize = '정리할 파일이 없습니다.';
  static const String aiAnalyzingFiles = 'AI가 파일을 분석 중입니다...';
  static const String aiFailedToClassify = 'AI가 분류할 파일을 찾지 못했습니다.';
  static const String movingFiles = '파일을 이동 중입니다...';
  static const String undoingFiles = '파일을 되돌리는 중입니다...';
  static const String errorDuringOrganization = '파일 정리 중 오류 발생:';

  // Generic dialogs
  static const String deleteConfirmTitle = '삭제 확인';
  static String deleteConfirmContent(int count) => '선택한 파일 $count개를 삭제하시겠습니까?';
  static const String fileAlreadyExistsTitle = '파일이 이미 존재합니다';
  static String fileAlreadyExistsContent(String name) => '"$name" 파일이 이미 존재합니다. 덮어쓰시겠습니까?';
  static String renameAlreadyExistsContent(String name) => '"$name" 이름의 항목이 이미 존재합니다.';
}
