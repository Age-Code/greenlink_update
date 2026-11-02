// 앱 테마 — 색상, 폰트, 컴포넌트 스타일

import 'package:flutter/material.dart';

// 앱 색상 토큰
class AppColors {
  static const Color primary = Color(0xFF98D471); // logo leaf green
  static const Color primaryFocus = Color(0xFF7FC65A); // selected border / focus ring
  static const Color primaryStrong = Color(0xFF5FAF3E); // text links on white bg
  static const Color primaryOnDark = Color(0xFFB8E59F); // emphasis on dark sections
  static const Color primarySoft = Color(0xFFEAF7DD); // chip bg / success bg

  static const Color onPrimary = Color(0xFF1F241F);

  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFFAF6EE); // logo cream
  static const Color canvasGreenTint = Color(0xFFF2F8EC); // very faint green
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfacePearl = Color(0xFFFAFAF7); // secondary panel bg
  static const Color surfaceDark = Color(0xFF1F241F); // dark section
  static const Color surfaceDark2 = Color(0xFF252B25); // dark card bg

  static const Color hairline = Color(0x14000000); // rgba(0,0,0,0.08)

  static const Color ink = Color(0xFF1D1D1F); // heading / key text
  static const Color body = Color(0xFF2A2A2A); // body text
  static const Color bodyMuted = Color(0xFF6E746C); // secondary / metadata
  static const Color bodySoft = Color(0xFF8A9286); // helper / timestamp
  static const Color bodyOnDark = Color(0xFFFFFFFF);
  static const Color bodyMutedOnDark = Color(0xFFC9D3C6);

  static const Color successBg = Color(0xFFEAF7DD);
  static const Color successText = Color(0xFF3F7F30);
  static const Color successBorder = Color(0xFFB8E59F);

  static const Color warningBg = Color(0xFFFFF4D8);
  static const Color warningText = Color(0xFF8A6500);
  static const Color warningBorder = Color(0xFFF0D88A);

  static const Color dangerBg = Color(0xFFFDECEC);
  static const Color dangerText = Color(0xFFB04444);
  static const Color dangerBorder = Color(0xFFF2B8B8);

  static const Color infoBg = Color(0xFFEEF6F8);
  static const Color infoText = Color(0xFF3F7480);
  static const Color infoBorder = Color(0xFFB8DDE5);
}

// 앱 테마 설정
class AppTheme {
  static const Color background = AppColors.canvasSoft;
  static const Color cardBackground = AppColors.surfaceCard;
  static const Color primaryGreen = AppColors.primary;
  static const Color softGreen = AppColors.primarySoft;
  static const Color deepGreen = AppColors.primaryStrong;
  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = AppColors.bodyMuted;
  static const Color borderSoft = AppColors.hairline;

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.canvas,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.primaryStrong,
        onSecondary: AppColors.canvas,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.ink,
        // ignore: deprecated_member_use
        background: AppColors.canvas,
        error: AppColors.dangerText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        shadowColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        // display → page title 32px/600
        displayLarge: TextStyle(color: AppColors.ink, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.2),
        // headline → section title 24px/600
        headlineLarge: TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
        headlineMedium: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        headlineSmall: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
        // title → card title 18px/600
        titleLarge: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
        titleMedium: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        titleSmall: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
        // body
        bodyLarge: TextStyle(color: AppColors.body, fontSize: 17, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: TextStyle(color: AppColors.body, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(color: AppColors.bodyMuted, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
        // label / caption
        labelLarge: TextStyle(color: AppColors.body, fontSize: 15, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: AppColors.bodyMuted, fontSize: 14, fontWeight: FontWeight.w400),
        labelSmall: TextStyle(color: AppColors.bodySoft, fontSize: 13, fontWeight: FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.hairline, width: 1),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryStrong,
          side: const BorderSide(color: AppColors.primary),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryStrong,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.canvas,
        selectedColor: AppColors.primarySoft,
        labelStyle: const TextStyle(color: AppColors.body, fontSize: 14),
        secondaryLabelStyle: const TextStyle(color: AppColors.primaryStrong, fontSize: 14, fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.hairline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        hintStyle: const TextStyle(color: AppColors.bodySoft, fontSize: 16),
        labelStyle: const TextStyle(color: AppColors.bodyMuted, fontSize: 15, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dangerBorder),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dangerText, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        selectedItemColor: AppColors.primaryStrong,
        unselectedItemColor: AppColors.bodyMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(color: AppColors.bodyOnDark, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryStrong,
        linearTrackColor: AppColors.primarySoft,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
