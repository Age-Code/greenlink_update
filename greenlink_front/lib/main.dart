// 앱 진입점 — Kakao SDK 초기화, 테마 적용

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'core/network/api_client.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_page.dart';
import 'screens/splash_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _isRedirectingToLogin = false;

// 앱 실행 — Kakao SDK 초기화 후 runApp 호출
void main() {
  // 플러그인(SharedPreferences, Kakao)을 runApp 전에 쓰므로 바인딩을 먼저 초기화한다.
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화 — 키를 바꾸면 AndroidManifest.xml·Info.plist·auth_service.dart도 함께 바꾼다.
  KakaoSdk.init(nativeAppKey: '20675888d2a1900e54cd1d88d75e4688');
  ApiClient.onUnauthorized = () async {
    if (_isRedirectingToLogin) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    _isRedirectingToLogin = true;
    try {
      await navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } finally {
      _isRedirectingToLogin = false;
    }
  };
  runApp(const GreenLinkApp());
}

// GreenLinkApp — 앱 진입점 — Kakao SDK 초기화, 테마 적용
class GreenLinkApp extends StatelessWidget {
  const GreenLinkApp({Key? key}) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'GreenLink',
      theme: AppTheme.lightTheme,
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
