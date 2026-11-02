// 토큰 저장소 — SharedPreferences 기반

import 'package:shared_preferences/shared_preferences.dart';

// 토큰 저장소 — SharedPreferences 기반
class TokenStorage {
  static const String _tokenKey = 'access_token';

  // Access token 저장
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Access token 조회
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Access token 삭제
  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
