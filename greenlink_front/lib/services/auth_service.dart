// 인증 서비스 — 로그인/회원가입/OAuth/토큰 처리

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../core/network/token_storage.dart';
import '../models/auth_models.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:google_sign_in/google_sign_in.dart';

// AuthService — Backend API 호출
class AuthService {
  final ApiClient _client = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  // 이메일 로그인 API 호출
  Future<ApiResponse<LoginResponse>> login(
    String email,
    String password,
  ) async {
    debugPrint('[AuthService] 🔐 로그인 시도 — email: $email');
    try {
      final response = await _client.post(
        ApiPaths.login,
        body: {'email': email, 'password': password},
      );

      if (response['success'] == true && response['data'] != null) {
        final loginData = LoginResponse.fromJson(response['data']);
        await _tokenStorage.saveAccessToken(loginData.accessToken);
        debugPrint('[AuthService] ✅ 로그인 성공 — token 저장 완료');
        debugPrint('[AuthService]   nickname: ${loginData.user.nickname}');
        return ApiResponse<LoginResponse>(
          success: true,
          message: response['message'] ?? '로그인 성공',
          data: loginData,
        );
      } else {
        debugPrint('[AuthService] ❌ 로그인 실패 — ${response['message']}');
        return ApiResponse<LoginResponse>(
          success: false,
          message: response['message'] ?? '로그인에 실패했습니다.',
        );
      }
    } catch (e) {
      debugPrint('[AuthService] ❌ 로그인 예외: $e');
      return ApiResponse<LoginResponse>(
        success: false,
        message: '로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 회원가입 API 호출
  Future<ApiResponse<Map<String, dynamic>>> signup(
    String email,
    String password,
    String nickname,
  ) async {
    debugPrint('[AuthService] 📝 회원가입 시도 — email: $email, nickname: $nickname');
    try {
      final response = await _client.post(
        ApiPaths.signup,
        body: {'email': email, 'password': password, 'nickname': nickname},
      );
      return ApiResponse<Map<String, dynamic>>(
        success: response['success'] ?? false,
        message: response['message'] ?? '회원가입이 완료되었습니다.',
        data: response['data'],
      );
    } catch (e) {
      debugPrint('[AuthService] ❌ 회원가입 예외: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: '회원가입 중 오류가 발생했습니다: $e',
      );
    }
  }

  // Kakao 로그인 API 호출
  Future<ApiResponse<LoginResponse>> loginWithKakao() async {
    debugPrint('[AuthService] 🟨 카카오 로그인 시도 (인가 코드 방식)');
    try {
      // 1. 인가 코드 받기
      String code = await kakao.AuthCodeClient.instance.authorize(
        redirectUri: 'kakao20675888d2a1900e54cd1d88d75e4688://oauth',
      );

      // 2. 백엔드로 code 전달
      final response = await _client.post(
        ApiPaths.kakaoLogin,
        body: {
          'code': code,
          'redirectUri': 'kakao20675888d2a1900e54cd1d88d75e4688://oauth',
        },
      );

      return _handleLoginResponse(response, '카카오');
    } catch (e) {
      debugPrint('[AuthService] ❌ 카카오 로그인 예외: $e');
      return ApiResponse<LoginResponse>(
        success: false,
        message: '카카오 로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // Google 로그인 API 호출
  Future<ApiResponse<LoginResponse>> loginWithGoogle() async {
    debugPrint('[AuthService] 🟦 구글 로그인 시도 (Server Auth Code 방식)');
    try {
      // 1. 구글 로그인 및 인가 코드 요청
      // backend의 client-id를 serverClientId로 사용
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '1042440953157-7ts5sfinq6slmt1p3arkdcuknt65g8lk.apps.googleusercontent.com',
        serverClientId:
            '1042440953157-r2iqcnd7hk7s94u16es2l5b2rno0em8q.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return ApiResponse<LoginResponse>(
          success: false,
          message: '구글 로그인이 취소되었습니다.',
        );
      }

      final String? code = googleUser.serverAuthCode;
      if (code == null) {
        return ApiResponse<LoginResponse>(
          success: false,
          message: '구글 인가 코드를 가져오지 못했습니다.',
        );
      }

      // 2. 백엔드로 code 전달
      final response = await _client.post(
        ApiPaths.googleLogin,
        body: {
          'code': code,
          'redirectUri':
              '', // Google의 경우 백엔드에서 redirectUri를 무시하거나 빈 값으로 처리 가능하도록 확인 필요
        },
      );

      return _handleLoginResponse(response, '구글');
    } catch (e) {
      debugPrint('[AuthService] ❌ 구글 로그인 예외: $e');
      return ApiResponse<LoginResponse>(
        success: false,
        message: '구글 로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 로그인 응답 처리 — 토큰 저장 후 공통 응답 반환
  Future<ApiResponse<LoginResponse>> _handleLoginResponse(
    dynamic response,
    String provider,
  ) async {
    if (response['success'] == true && response['data'] != null) {
      final loginData = LoginResponse.fromJson(response['data']);
      await _tokenStorage.saveAccessToken(loginData.accessToken);
      debugPrint('[AuthService] ✅ $provider 로그인 성공 — token 저장 완료');
      return ApiResponse<LoginResponse>(
        success: true,
        message: response['message'] ?? '$provider 로그인 성공',
        data: loginData,
      );
    } else {
      debugPrint('[AuthService] ❌ $provider 로그인 실패 — ${response['message']}');
      return ApiResponse<LoginResponse>(
        success: false,
        message: response['message'] ?? '$provider 로그인에 실패했습니다.',
      );
    }
  }

  // 비밀번호 변경 — 성공 시 현재 로컬 토큰 삭제
  Future<ApiResponse<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    debugPrint('[AuthService] 🔐 비밀번호 변경 요청');
    try {
      final response = await _client.patch(
        ApiPaths.changePassword,
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (response['success'] == true) {
        await _tokenStorage.clearAccessToken();
      }

      return ApiResponse<void>(
        success: response['success'] == true,
        message: response['message'] ?? '',
      );
    } catch (e) {
      debugPrint('[AuthService] ❌ 비밀번호 변경 예외: $e');
      return ApiResponse<void>(
        success: false,
        message: '비밀번호 변경 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 회원 탈퇴 — 성공 시 로컬 토큰 삭제
  Future<ApiResponse<void>> withdraw() async {
    debugPrint('[AuthService] 🗑️ 회원 탈퇴 요청');
    try {
      final response = await _client.delete(ApiPaths.withdraw);

      if (response['success'] == true) {
        await _tokenStorage.clearAccessToken();
      }

      return ApiResponse<void>(
        success: response['success'] == true,
        message: response['message'] ?? '',
      );
    } catch (e) {
      debugPrint('[AuthService] ❌ 회원 탈퇴 예외: $e');
      return ApiResponse<void>(
        success: false,
        message: '회원 탈퇴 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 로그아웃 처리 — 서버 로그아웃 실패와 무관하게 저장된 토큰 삭제
  Future<void> logout() async {
    debugPrint('[AuthService] 🚪 로그아웃 — 서버 로그아웃 요청 후 token 삭제');
    try {
      await _client.post(ApiPaths.logout, body: {});
    } catch (e) {
      debugPrint('[AuthService] ⚠️ 서버 로그아웃 실패 — 로컬 로그아웃 계속 진행: $e');
    }
    await _tokenStorage.clearAccessToken();
  }

  // 로그인 상태 확인 — 저장 토큰 존재 여부 반환
  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getAccessToken();
    final loggedIn = token != null && token.isNotEmpty;
    debugPrint('[AuthService] 🔍 로그인 상태 확인: $loggedIn');
    return loggedIn;
  }
}
