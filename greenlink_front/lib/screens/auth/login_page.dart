// 로그인 화면 — 이메일/Kakao/Google 로그인

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/greenlink_button.dart';
import 'signup_page.dart';
import '../main_page.dart';

// LoginPage — 화면 위젯
class LoginPage extends StatefulWidget {
  // State 객체 생성
  @override
  _LoginPageState createState() => _LoginPageState();
}

// _LoginPageState — 화면 상태와 이벤트 처리
class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController(text: '');
  final _passwordCtrl = TextEditingController(text: '');
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // 리소스 정리
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // 이메일 로그인 처리 — 성공 시 메인 화면 이동
  void _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _authService.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainPage()));
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  // Kakao 로그인 처리
  void _loginWithKakao() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final res = await _authService.loginWithKakao();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainPage()));
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  // Google 로그인 처리
  void _loginWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final res = await _authService.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainPage()));
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.eco_rounded, size: 36, color: AppColors.primaryStrong),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GreenLink',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '오늘도 식물 친구를 만나러 가볼까요?',
                      style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              const Text('이메일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.body)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: const InputDecoration(
                  hintText: '이메일 주소를 입력해주세요',
                  prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.bodyMuted),
                ),
              ),
              const SizedBox(height: 16),

              const Text('비밀번호', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.body)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력해주세요',
                  prefixIcon: const Icon(Icons.lock_outlined, size: 20, color: AppColors.bodyMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.bodyMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.dangerText, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              GreenlinkButton(
                text: '로그인',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _login,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage())),
                  child: const Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(color: AppColors.primaryStrong, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.hairline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '소셜 계정으로 로그인',
                      style: TextStyle(color: AppColors.bodySoft, fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.hairline)),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialLoginButton(
                    onTap: _isLoading ? null : _loginWithKakao,
                    color: const Color(0xFFFEE500),
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFF391B1B),
                    label: '카카오',
                  ),
                  const SizedBox(width: 20),
                  _SocialLoginButton(
                    onTap: _isLoading ? null : _loginWithGoogle,
                    color: AppColors.canvas,
                    icon: Icons.g_mobiledata_rounded,
                    iconSize: 36,
                    iconColor: const Color(0xFF4285F4),
                    label: 'Google',
                    hasBorder: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// _SocialLoginButton — 내부 위젯
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final bool hasBorder;

  const _SocialLoginButton({
    this.onTap,
    required this.color,
    required this.icon,
    required this.iconColor,
    this.iconSize = 22,
    required this.label,
    this.hasBorder = false,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: hasBorder ? Border.all(color: AppColors.hairline) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: iconColor)),
          ],
        ),
      ),
    );
  }
}
