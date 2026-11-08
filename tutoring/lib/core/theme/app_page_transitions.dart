import 'package:flutter/material.dart';

/// Pages appear in place instead of sliding or fading in. Applied to every
/// platform through `ThemeData.pageTransitionsTheme`, so go_router's default
/// `MaterialPage` routes switch instantly as well.
class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

PageTransitionsTheme instantPageTransitions() => PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const InstantPageTransitionsBuilder(),
  },
);
