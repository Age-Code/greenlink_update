import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const screen = 28.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const field = 14.0;
  static const segment = 18.0;
  static const card = 24.0;
}

/// Window width classes. Every responsive decision in the app uses one of
/// these three; screens must not invent other width thresholds.
enum ScreenType { mobile, tablet, desktop }

/// mobile < 600, tablet 600–1199, desktop ≥ 1200 (logical pixels).
abstract final class AppBreakpoints {
  static const tablet = 600.0;
  static const desktop = 1200.0;

  static ScreenType of(double width) {
    if (width < tablet) return ScreenType.mobile;
    if (width < desktop) return ScreenType.tablet;
    return ScreenType.desktop;
  }
}

extension ScreenTypeContext on BuildContext {
  /// Width class of the current window.
  ScreenType get screenType =>
      AppBreakpoints.of(MediaQuery.sizeOf(this).width);
}

/// Shared layout for every signed-in screen.
///
/// The body is a centered column ([contentMaxWidth] by default); the rest of
/// the window shows the page background. Top bars, page bodies, and bottom
/// bars share the same side padding, so controls line up between screens.
abstract final class AppLayout {
  /// Side padding on tablet and desktop.
  static const horizontalPadding = AppSpacing.xl;

  /// Side padding on mobile.
  static const mobileHorizontalPadding = AppSpacing.lg;

  static const topBarHeight = 64.0;
  static const bodyTopPadding = 28.0;
  static const bodyBottomPadding = 80.0;

  /// Default content column (Figma Page 2 centered column).
  static const contentMaxWidth = 780.0;

  /// Note reader column (Figma 06_Note_Reader).
  static const readingMaxWidth = 720.0;

  /// Home dashboard column (Figma 01_Home tablet container).
  static const dashboardMaxWidth = 1024.0;

  /// Fixed left class menu on desktop.
  static const sidebarWidth = 280.0;

  /// Smallest height of anything tappable on mobile.
  static const minTouchHeight = 48.0;

  static double horizontalPaddingFor(ScreenType type) =>
      type == ScreenType.mobile ? mobileHorizontalPadding : horizontalPadding;
}

@immutable
class StudyTogetherTokens extends ThemeExtension<StudyTogetherTokens> {
  const StudyTogetherTokens({required this.ctaShadow});

  final List<BoxShadow> ctaShadow;

  @override
  StudyTogetherTokens copyWith({List<BoxShadow>? ctaShadow}) =>
      StudyTogetherTokens(ctaShadow: ctaShadow ?? this.ctaShadow);

  @override
  StudyTogetherTokens lerp(
    covariant ThemeExtension<StudyTogetherTokens>? other,
    double t,
  ) {
    if (other is! StudyTogetherTokens) return this;
    return StudyTogetherTokens(
      ctaShadow: BoxShadow.lerpList(ctaShadow, other.ctaShadow, t) ?? ctaShadow,
    );
  }
}
