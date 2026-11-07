// 회원가입 화면 — 이메일 회원가입

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/greenlink_button.dart';

// SignupPage — 화면 위젯
class SignupPage extends StatefulWidget {
  // State 객체 생성
  @override
  _SignupPageState createState() => _SignupPageState();
}

// _SignupPageState — 화면 상태와 이벤트 처리
class _SignupPageState extends State<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  // 리소스 정리
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  // 회원가입 처리 — 성공 시 로그인 화면 복귀
  void _signup() async {
    if (_isLoading) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final nickname = _nicknameCtrl.text.trim();
    final validationMessage = validateSignupInput(email, password, nickname);
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authService.signup(email, password, nickname);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(labelText: "닉네임"),
            ),
            const SizedBox(height: 32),
            GreenlinkButton(
              text: "회원가입",
              isLoading: _isLoading,
              onPressed: _signup,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("로그인 화면으로 돌아가기"),
            )
          ],
        ),
      ),
    );
  }
}

// 회원가입 입력 검증 — 서버 규칙(이메일 형식, 비밀번호 8자 이상, 닉네임 1~50자)과 같다.
// 문제가 없으면 null을 돌려준다.
String? validateSignupInput(String email, String password, String nickname) {
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(email)) return '올바른 이메일 주소를 입력해주세요.';
  if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
  if (password.length > 100) return '비밀번호는 100자 이하여야 합니다.';
  if (nickname.isEmpty) return '닉네임을 입력해주세요.';
  if (nickname.length > 50) return '닉네임은 50자 이하여야 합니다.';
  return null;
}
