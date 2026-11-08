import 'package:flutter/material.dart';

/// Scrolling without visible scrollbars on every platform. Desktop and web
/// normally wrap scroll views in a `Scrollbar`; the design hides it, so
/// [buildScrollbar] returns the content untouched. Overscroll glow and
/// mouse-wheel behaviour stay the Material defaults.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
