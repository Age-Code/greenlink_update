import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

/// Modal surface that follows the window: full-width bottom sheet on mobile,
/// an inset bottom sheet with 64px side margins on tablet, a centered dialog
/// on desktop.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final screenType = context.screenType;
  if (screenType == ScreenType.desktop) {
    return showDialog<T>(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: builder(context),
            ),
          ),
    );
  }
  final width = MediaQuery.sizeOf(context).width;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    constraints:
        screenType == ScreenType.tablet
            ? BoxConstraints(maxWidth: width - 2 * 64)
            : null,
    builder: builder,
  );
}
