// 공통 로딩 위젯

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// GreenlinkLoading — 공통 로딩 위젯
class GreenlinkLoading extends StatelessWidget {
  final String? message;
  const GreenlinkLoading({Key? key, this.message}) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryStrong,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.bodyMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
