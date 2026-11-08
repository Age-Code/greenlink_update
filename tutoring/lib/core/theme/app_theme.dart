import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_page_transitions.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const baseText = TextStyle(
      fontFamily: 'Noto Sans KR',
      fontFamilyFallback: ['Apple SD Gothic Neo', 'sans-serif'],
      color: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: instantPageTransitions(),
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.coral,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        headlineMedium: baseText.copyWith(
          fontSize: 28,
          height: 1.4,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseText.copyWith(
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: baseText.copyWith(fontSize: 15, height: 1.4),
        labelLarge: baseText.copyWith(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: baseText.copyWith(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: baseText.copyWith(
          fontSize: 13,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 13),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.field)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.field)),
          borderSide: BorderSide(color: AppColors.coralDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.field)),
          borderSide: BorderSide(color: AppColors.coralDark),
        ),
      ),
      extensions: const [
        StudyTogetherTokens(
          ctaShadow: [
            BoxShadow(
              color: Color(0x2EEB8A69),
              offset: Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
      ],
    );
  }
}
