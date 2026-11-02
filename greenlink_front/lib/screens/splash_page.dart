// 스플래시 화면 — 토큰 확인 후 홈 또는 로그인 이동

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth/login_page.dart';
import 'main_page.dart';

// SplashPage — 화면 위젯
class SplashPage extends StatefulWidget {
  // State 객체 생성
  @override
  _SplashPageState createState() => _SplashPageState();
}

// _SplashPageState — 화면 상태와 이벤트 처리
class _SplashPageState extends State<SplashPage> {
  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // 인증 확인 — 토큰 유무에 따라 다음 화면 이동
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty && token != 'mock_token') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainPage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasSoft,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark — leaf symbol
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 48,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GreenLink',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '나만의 반려식물 성장 서비스',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.bodyMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
