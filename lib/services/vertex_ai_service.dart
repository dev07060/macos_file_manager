import 'dart:convert';
import 'dart:developer';
import 'dart:io' show File;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

class VertexAIService {
  final String _projectId = 'macos-file-manager';
  final String _modelId = 'gemini-2.0-flash-001';
  final String? _serviceAccountKeyPath = dotenv.env['SERVICE_ACCOUNT_KEY_PATH'];
  auth.AccessCredentials? _credentials;

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

  Future<String?> classifyFile(String fileName, String contentSnippet) async {
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

    final prompt = """
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
        final category = decodedResponse['candidates'][0]['content']['parts'][0]['text'].trim();
        if (_credentials!.accessToken.hasExpired) {
          log('Vertex AI access token expired, will re-initialize on next call or if handled by client library.');
        }
        return category;
      } else {
        log('Vertex AI Error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error calling Vertex AI: $e');
      return null;
    }
  }
}

final vertexAIServiceProvider = FutureProvider<VertexAIService>((ref) async {
  final service = VertexAIService();
  await service._initializeAuth();
  return service;
});
