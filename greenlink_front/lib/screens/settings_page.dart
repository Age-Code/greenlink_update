// 설정 화면 — 로그아웃

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';

// 설정 화면 — 로그아웃 제공
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // 로그인 화면 이동 — 현재 navigation stack 제거
  void _goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  // 스낵바 표시 — 기존 메시지를 지운 뒤 새 메시지 노출
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // 비밀번호 변경 처리 — 성공 시 토큰 삭제 후 로그인 화면 이동
  Future<void> _changePassword(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    final successMessage = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setState) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.primaryStrong,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '비밀번호 변경',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '현재 비밀번호를 확인한 뒤 새 비밀번호로 변경합니다.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.bodyMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: '현재 비밀번호'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '현재 비밀번호를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: '새 비밀번호'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '새 비밀번호를 입력해주세요.';
                        }
                        if (value.length < 4) {
                          return '새 비밀번호는 4자 이상이어야 합니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setState(() => isSubmitting = true);
                                    final result = await AuthService()
                                        .changePassword(
                                          currentPasswordController.text,
                                          newPasswordController.text,
                                        );

                                    if (!ctx.mounted ||
                                        !dialogContext.mounted) {
                                      return;
                                    }

                                    if (result.success) {
                                      Navigator.pop(
                                        dialogContext,
                                        result.message.isNotEmpty
                                            ? result.message
                                            : '비밀번호가 변경되었습니다. 다시 로그인해주세요.',
                                      );
                                      return;
                                    }

                                    setState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      _showSnackBar(
                                        context,
                                        result.message.isNotEmpty
                                            ? result.message
                                            : '비밀번호 변경에 실패했습니다.',
                                      );
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '변경',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();

    if (successMessage == null || !context.mounted) return;

    _showSnackBar(context, successMessage);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!context.mounted) return;
    _goToLogin(context);
  }

  // 회원 탈퇴 처리 — 확인 후 soft delete 요청, 성공 시 로그인 화면 이동
  Future<void> _withdraw(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: AppColors.dangerText,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '회원 탈퇴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '정말 탈퇴하시겠어요? 이 작업은 되돌릴 수 없습니다.',
                style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerBg,
                        foregroundColor: AppColors.dangerText,
                        side: const BorderSide(color: AppColors.dangerBorder),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '탈퇴',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !context.mounted) return;

    final result = await AuthService().withdraw();

    if (!context.mounted) return;
    _showSnackBar(
      context,
      result.message.isNotEmpty ? result.message : '회원 탈퇴 요청에 실패했습니다.',
    );

    if (!result.success) return;

    await Future.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) return;
    _goToLogin(context);
  }

  // 로그아웃 처리 — 토큰 삭제 후 로그인 화면 이동
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.dangerText,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '정말 로그아웃 하시겠어요?',
                style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerBg,
                        foregroundColor: AppColors.dangerText,
                        side: const BorderSide(color: AppColors.dangerBorder),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    debugPrint('[SettingsPage] 🚪 로그아웃 실행');
    await AuthService().logout();

    if (!context.mounted) return;
    _goToLogin(context);
  }

  // 계정 관리 항목 렌더링
  Widget _accountTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = AppColors.ink,
    Color trailingColor = AppColors.bodySoft,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.bodyMuted, fontSize: 14),
      ),
      trailing: Icon(Icons.chevron_right, color: trailingColor, size: 20),
      onTap: onTap,
    );
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('계정'),
        backgroundColor: AppColors.canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          // 섹션 레이블
          const Text(
            '계정 관리',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.bodyMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                _accountTile(
                  icon: Icons.lock_reset_rounded,
                  iconBg: AppColors.primarySoft,
                  iconColor: AppColors.primaryStrong,
                  title: '비밀번호 변경',
                  subtitle: '현재 비밀번호 확인 후 변경합니다',
                  onTap: () => _changePassword(context),
                ),
                const Divider(indent: 20, endIndent: 20),
                _accountTile(
                  icon: Icons.person_remove_rounded,
                  iconBg: AppColors.dangerBg,
                  iconColor: AppColors.dangerText,
                  title: '회원 탈퇴',
                  subtitle: '계정을 탈퇴하고 토큰을 무효화합니다',
                  titleColor: AppColors.dangerText,
                  trailingColor: AppColors.dangerText,
                  onTap: () => _withdraw(context),
                ),
                const Divider(indent: 20, endIndent: 20),
                _accountTile(
                  icon: Icons.logout_rounded,
                  iconBg: AppColors.dangerBg,
                  iconColor: AppColors.dangerText,
                  title: '로그아웃',
                  subtitle: '계정에서 로그아웃합니다',
                  titleColor: AppColors.dangerText,
                  trailingColor: AppColors.dangerText,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 앱 정보
          const Text(
            '앱 정보',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.bodyMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.hairline),
            ),
            child: const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Icon(
                Icons.eco_rounded,
                color: AppColors.primaryStrong,
                size: 22,
              ),
              title: Text(
                'GreenLink',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '나만의 반려식물 성장 서비스',
                style: TextStyle(color: AppColors.bodyMuted, fontSize: 14),
              ),
              trailing: Text(
                'v1.0.0',
                style: TextStyle(color: AppColors.bodySoft, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
