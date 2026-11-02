// 공통 버튼 위젯

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ButtonType — 공통 버튼 위젯
enum ButtonType { primary, secondary, ghost, danger, disabled }

// GreenlinkButton — 공통 버튼 위젯
class GreenlinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const GreenlinkButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    Color bgColor;
    Color fgColor;
    Border? border;

    if (isDisabled && type != ButtonType.danger) {
      bgColor = const Color(0xFFF0F0EE);
      fgColor = AppColors.bodySoft;
      border = null;
    } else {
      switch (type) {
        case ButtonType.primary:
          bgColor = AppColors.primary;
          fgColor = AppColors.onPrimary;
          break;
        case ButtonType.secondary:
          bgColor = Colors.transparent;
          fgColor = AppColors.primaryStrong;
          border = Border.all(color: AppColors.primary);
          break;
        case ButtonType.ghost:
          bgColor = Colors.transparent;
          fgColor = AppColors.primaryStrong;
          break;
        case ButtonType.danger:
          bgColor = AppColors.dangerBg;
          fgColor = AppColors.dangerText;
          border = Border.all(color: AppColors.dangerBorder);
          break;
        case ButtonType.disabled:
          bgColor = const Color(0xFFF0F0EE);
          fgColor = AppColors.bodySoft;
          break;
      }
    }

    Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: fgColor,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTapDown: (_) {},
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: const StadiumBorder(),
              padding: EdgeInsets.zero,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                fgColor.withValues(alpha: 0.08),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: border,
                borderRadius: BorderRadius.circular(9999),
              ),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
