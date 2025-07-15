import 'dart:convert';
import 'dart:developer';
import 'dart:io' show File;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

// 정리 방식 열거형
enum OrganizationMethod {
  category, // 카테고리별 정리
  date, // 날짜별 정리
  fileType, // 파일 타입별 정리
  size, // 크기별 정리
  importance, // 중요도별 정리
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

class VertexAIService {
  final String _projectId = 'macos-file-manager';
  final String _modelId = 'gemini-2.0-flash-001';
  final String? _serviceAccountKeyPath = dotenv.env['SERVICE_ACCOUNT_KEY_PATH'];
  auth.AccessCredentials? _credentials;

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
      method: OrganizationMethod.importance,
      displayName: '중요도별 정리',
      description: 'AI가 파일의 중요도를 분석하여 정리합니다',
      icon: '⭐',
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

  VertexAIService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (_serviceAccountKeyPath == null || _serviceAccountKeyPath.isEmpty) {
      log('Service account key path not found in .env file. Please set SERVICE_ACCOUNT_KEY_PATH.');
      return;
    }
    try {
      final jsonCredentials = await File(_serviceAccountKeyPath).readAsString();
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
      _credentials = client.credentials;
      log('Successfully obtained Vertex AI credentials.');
    } catch (e) {
      log(
        'Error initializing Vertex AI auth: $e. Make sure the service account key path is correct and the file is accessible.',
      );
    }
  }

  // 기존 메서드 - 카테고리별 분류
  Future<String?> classifyFile(String fileName, String contentSnippet) async {
    return await _callVertexAI(_getCategoryPrompt(fileName, contentSnippet));
  }

  // 새로운 메서드 - 다양한 정리 방식 지원
  Future<String?> organizeFile(
    String fileName,
    String contentSnippet,
    OrganizationMethod method, {
    String? customPrompt,
    Map<String, dynamic>? fileMetadata,
  }) async {
    String prompt;

    switch (method) {
      case OrganizationMethod.category:
        prompt = _getCategoryPrompt(fileName, contentSnippet);
        break;
      case OrganizationMethod.date:
        prompt = _getDatePrompt(fileName, contentSnippet, fileMetadata);
        break;
      case OrganizationMethod.fileType:
        prompt = _getFileTypePrompt(fileName, contentSnippet);
        break;
      case OrganizationMethod.size:
        prompt = _getSizePrompt(fileName, contentSnippet, fileMetadata);
        break;
      case OrganizationMethod.importance:
        prompt = _getImportancePrompt(fileName, contentSnippet);
        break;
      case OrganizationMethod.project:
        prompt = _getProjectPrompt(fileName, contentSnippet);
        break;
      case OrganizationMethod.custom:
        prompt = customPrompt ?? _getCategoryPrompt(fileName, contentSnippet);
        break;
    }

    return await _callVertexAI(prompt);
  }

  // AI API 호출 공통 메서드
  Future<String?> _callVertexAI(String prompt) async {
    if (_credentials == null) {
      log('Vertex AI client not initialized or authentication failed.');
      await _initializeAuth();
      if (_credentials == null) {
        log('Still unable to initialize Vertex AI client after re-attempt.');
        return null;
      }
    }

    final url = Uri.parse(
      'https://us-central1-aiplatform.googleapis.com/v1/projects/$_projectId/locations/us-central1/publishers/google/models/$_modelId:generateContent',
    );

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer ${_credentials!.accessToken.data}', 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final result = decodedResponse['candidates'][0]['content']['parts'][0]['text'].trim();
        if (_credentials!.accessToken.hasExpired) {
          log('Vertex AI access token expired, will re-initialize on next call or if handled by client library.');
        }
        return result;
      } else {
        log('Vertex AI Error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error calling Vertex AI: $e');
      return null;
    }
  }

  // 카테고리별 정리 프롬프트
  String _getCategoryPrompt(String fileName, String contentSnippet) {
    return """
      당신은 파일을 정리하는 전문가입니다. 파일 이름과 내용 일부를 보고, 다음 카테고리 중 하나로 분류하세요:
      '청구서', '계약서', '보고서', '프레젠테이션', '이미지', '동영상', '소스코드', '기타'.
      오직 카테고리 이름 하나만 한국어로 반환하세요.

      ---
      예시 1:
      파일 이름: invoice_q4.pdf
      내용: "Invoice #1234, Due Date..."
      결과: 청구서
      ---
      예시 2:
      파일 이름: main.dart
      내용: "import 'package:flutter/material.dart';"
      결과: 소스코드
      ---
      예시 3:
      파일 이름: vacation.jpg
      내용: ""
      결과: 이미지
      ---
      실제 분류:
      파일 이름: $fileName
      내용: "$contentSnippet"
      결과:
    """;
  }

  // 날짜별 정리 프롬프트
  String _getDatePrompt(String fileName, String contentSnippet, Map<String, dynamic>? metadata) {
    final fileDate = metadata?['creationDate'] ?? metadata?['modificationDate'] ?? DateTime.now();
    final dateTime = fileDate is DateTime ? fileDate : DateTime.tryParse(fileDate.toString()) ?? DateTime.now();

    return """
      파일을 날짜별로 정리합니다. 파일 정보를 분석하여 적절한 날짜 폴더명을 제안하세요.
      다음 형식 중 하나로 반환하세요: 'YYYY년', 'YYYY년 MM월', 'YYYY-MM-DD'
      
      파일 이름: $fileName
      파일 날짜: ${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일
      내용: "$contentSnippet"
      
      적절한 날짜 폴더명:
    """;
  }

  // 파일 타입별 정리 프롬프트
  String _getFileTypePrompt(String fileName, String contentSnippet) {
    return """
      파일을 타입별로 정리합니다. 파일 확장자와 내용을 분석하여 적절한 타입 폴더명을 제안하세요.
      다음 중 하나로 반환하세요: '문서', '이미지', '동영상', '음악', '압축파일', '실행파일', '소스코드', '기타'
      
      파일 이름: $fileName
      내용: "$contentSnippet"
      
      파일 타입:
    """;
  }

  // 크기별 정리 프롬프트
  String _getSizePrompt(String fileName, String contentSnippet, Map<String, dynamic>? metadata) {
    final fileSize = metadata?['size'] ?? 0;
    final sizeInMB = (fileSize as num) / (1024 * 1024);

    return """
      파일을 크기별로 정리합니다. 파일 크기에 따라 적절한 폴더명을 제안하세요.
      다음 중 하나로 반환하세요: '소용량 (1MB 미만)', '중용량 (1MB-10MB)', '대용량 (10MB-100MB)', '초대용량 (100MB 이상)'
      
      파일 이름: $fileName
      파일 크기: ${sizeInMB.toStringAsFixed(2)}MB
      내용: "$contentSnippet"
      
      크기 분류:
    """;
  }

  // 중요도별 정리 프롬프트
  String _getImportancePrompt(String fileName, String contentSnippet) {
    return """
      파일을 중요도별로 정리합니다. 파일 이름과 내용을 분석하여 중요도를 평가하세요.
      다음 중 하나로 반환하세요: '긴급', '중요', '보통', '참고용'
      
      평가 기준:
      - 긴급: 계약서, 청구서, 법적 문서 등
      - 중요: 보고서, 프레젠테이션, 핵심 소스코드 등
      - 보통: 일반 문서, 이미지, 일반 파일 등
      - 참고용: 임시 파일, 백업 파일, 로그 파일 등
      
      파일 이름: $fileName
      내용: "$contentSnippet"
      
      중요도:
    """;
  }

  // 프로젝트별 정리 프롬프트
  String _getProjectPrompt(String fileName, String contentSnippet) {
    return """
      파일을 프로젝트별로 정리합니다. 파일 이름과 내용을 분석하여 관련 프로젝트나 업무 영역을 파악하세요.
      구체적인 프로젝트명이나 업무 영역을 한국어로 제안하세요.
      
      예시: 'Flutter 앱 개발', '웹사이트 디자인', '재무 관리', '마케팅 자료', '개인 사진' 등
      
      파일 이름: $fileName
      내용: "$contentSnippet"
      
      프로젝트/업무 영역:
    """;
  }
}

final vertexAIServiceProvider = FutureProvider<VertexAIService>((ref) async {
  final service = VertexAIService();
  await service._initializeAuth();
  return service;
});
