// HTTP 클라이언트 — JWT 헤더 부착, 401 처리

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

// HTTP 클라이언트 — 공통 헤더와 응답 처리
class ApiClient {
  // 환경별 전환은 빌드 시 --dart-define=GREENLINK_API_BASE_URL=... 로 주입한다.
  // 지정하지 않으면 기존 운영 주소를 그대로 사용한다.
  static const String baseUrl = String.fromEnvironment(
    'GREENLINK_API_BASE_URL',
    defaultValue: 'https://likepigs.shop/api',
  );
  final TokenStorage _tokenStorage = TokenStorage();

  // 요청 타임아웃 — 서버 무응답 시 무한 대기 방지
  static const Duration requestTimeout = Duration(seconds: 15);

  // 타임아웃 응답 — 다른 오류와 동일한 형태로 반환
  Map<String, dynamic> _timeoutResponse(String method, String url) {
    debugPrint('[ApiClient] ⏱️ $method $url 응답 시간 초과');
    return {'success': false, 'message': '서버 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요.'};
  }

  // 401 발생 시 호출할 콜백
  static Function()? onUnauthorized;

  // 요청 헤더 생성 — 토큰이 있으면 Authorization 추가
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('[ApiClient] 🔑 Authorization 헤더 포함됨');
    } else {
      debugPrint('[ApiClient] ⚠️ Authorization 헤더 없음 — 토큰 미저장 상태');
    }
    return headers;
  }

  // GET 요청 실행 — 공통 응답 처리
  Future<dynamic> get(String path) async {
    final url = '$baseUrl$path';
    debugPrint('[ApiClient] → GET $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(requestTimeout);
      return await _processResponse('GET', url, response);
    } on TimeoutException {
      return _timeoutResponse('GET', url);
    } catch (e) {
      debugPrint('[ApiClient] ❌ GET $url 네트워크 오류: $e');
      return {'success': false, 'message': '네트워크 연결을 확인해주세요. ($e)'};
    }
  }

  // POST 요청 실행 — JSON body 전송 후 공통 응답 처리
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final url = '$baseUrl$path';
    debugPrint('[ApiClient] → POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return await _processResponse('POST', url, response);
    } on TimeoutException {
      return _timeoutResponse('POST', url);
    } catch (e) {
      debugPrint('[ApiClient] ❌ POST $url 네트워크 오류: $e');
      return {'success': false, 'message': '네트워크 연결을 확인해주세요. ($e)'};
    }
  }

  // PATCH 요청 실행 — JSON body 전송 후 공통 응답 처리
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final url = '$baseUrl$path';
    debugPrint('[ApiClient] → PATCH $url');
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return await _processResponse('PATCH', url, response);
    } on TimeoutException {
      return _timeoutResponse('PATCH', url);
    } catch (e) {
      debugPrint('[ApiClient] ❌ PATCH $url 네트워크 오류: $e');
      return {'success': false, 'message': '네트워크 연결을 확인해주세요. ($e)'};
    }
  }

  // DELETE 요청 실행 — JSON body 전송 후 공통 응답 처리
  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    final url = '$baseUrl$path';
    debugPrint('[ApiClient] → DELETE $url');
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return await _processResponse('DELETE', url, response);
    } on TimeoutException {
      return _timeoutResponse('DELETE', url);
    } catch (e) {
      debugPrint('[ApiClient] ❌ DELETE $url 네트워크 오류: $e');
      return {'success': false, 'message': '네트워크 연결을 확인해주세요. ($e)'};
    }
  }

  // HTTP 응답 처리 — 401이면 저장 토큰 삭제 후 로그인 이동 콜백 호출
  Future<dynamic> _processResponse(
    String method,
    String url,
    http.Response response,
  ) async {
    debugPrint('[ApiClient] ← $method $url → ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint(
          '[ApiClient]   ✅ success=${decoded['success']} message=${decoded['message']}',
        );
        return decoded;
      }
      return {'success': true, 'message': '요청 성공'};
    } else if (response.statusCode == 401) {
      debugPrint(
        '[ApiClient]   🔒 401 Unauthorized — token 삭제 후 onUnauthorized 콜백 호출',
      );
      await _tokenStorage.clearAccessToken();
      onUnauthorized?.call();
      return {'success': false, 'message': '로그인이 필요합니다. 다시 로그인해주세요.'};
    } else {
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          debugPrint(
            '[ApiClient]   ❌ ${response.statusCode} message=${decoded['message']}',
          );
          return decoded;
        } catch (_) {}
      }
      debugPrint('[ApiClient]   ❌ ${response.statusCode} — 서버 오류');
      return {
        'success': false,
        'message': '서버 오류가 발생했습니다. (${response.statusCode})',
      };
    }
  }
}
