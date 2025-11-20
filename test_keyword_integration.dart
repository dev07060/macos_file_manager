import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/keyword_mapping.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';
import 'package:macos_file_manager/services/file_organization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Mock SharedPreferences 설정
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);

  final service = container.read(fileOrganizationServiceProvider);

  // 테스트 설정: 키워드 매핑과 확장자 매핑이 모두 있는 경우
  final configNotifier = container.read(fileCategoryConfigProvider.notifier);

  // 키워드 매핑 추가
  final keywordMapping = KeywordMapping(
    pattern: 'report',
    category: '보고서',
    isRegex: false,
    caseSensitive: false,
    priority: 0,
  );

  configNotifier.addKeywordMapping(keywordMapping);

  // 테스트 실행
  debugPrint('=== 키워드 기반 파일 분류 테스트 ===');

  // 키워드 매칭 테스트 (report.pdf -> 보고서, 확장자 매핑보다 우선)
  final result1 = service.classifyFile('monthly_report.pdf', '');
  debugPrint('monthly_report.pdf -> $result1 (예상: 보고서)');

  // 확장자만 매칭되는 경우
  final result2 = service.classifyFile('document.pdf', '');
  debugPrint('document.pdf -> $result2 (예상: 문서)');

  // 키워드도 확장자도 매칭되지 않는 경우
  final result3 = service.classifyFile('unknown.xyz', '');
  debugPrint('unknown.xyz -> $result3 (예상: 기타)');

  // 정규식 패턴 테스트
  final regexMapping = KeywordMapping(
    pattern: r'\d{4}.*report',
    category: '연도별보고서',
    isRegex: true,
    caseSensitive: false,
    priority: 1,
  );

  configNotifier.addKeywordMapping(regexMapping);

  final result4 = service.classifyFile('2024_annual_report.pdf', '');
  debugPrint('2024_annual_report.pdf -> $result4 (예상: 보고서 또는 연도별보고서)');

  // 대소문자 구분 테스트
  final caseSensitiveMapping = KeywordMapping(
    pattern: 'Report',
    category: '대소문자구분보고서',
    isRegex: false,
    caseSensitive: true,
    priority: 2,
  );

  configNotifier.addKeywordMapping(caseSensitiveMapping);

  final result5 = service.classifyFile('Monthly_Report.pdf', '');
  debugPrint('Monthly_Report.pdf -> $result5 (예상: 대소문자구분보고서)');

  final result6 = service.classifyFile('monthly_report.pdf', '');
  debugPrint('monthly_report.pdf -> $result6 (예상: 보고서)');

  container.dispose();
  debugPrint('=== 테스트 완료 ===');
}
