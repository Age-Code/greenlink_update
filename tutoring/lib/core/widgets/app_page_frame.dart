import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

/// Full-width top bar. Its leading icon, title, and actions use the same side
/// padding as the page body. Pass it to `Scaffold.appBar`. An optional
/// [bottom] strip (for example a progress bar) hangs under the toolbar.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.leading,
    this.title,
    this.actions = const <Widget>[],
    this.centerTitle = true,
    this.showBrand = true,
    this.bottom,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;
  final bool centerTitle;
  final bool showBrand;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    AppLayout.topBarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.homeDivider)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppLayout.topBarHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.horizontalPaddingFor(
                      context.screenType,
                    ),
                  ),
                  child: NavigationToolbar(
                    centerMiddle: centerTitle,
                    middleSpacing: 12,
                    leading: leading,
                    middle:
                        showBrand
                            ? _TugetherTitle(title: title)
                            : title == null
                                ? null
                                : DefaultTextStyle.merge(
                                  style: const TextStyle(
                                    color: AppColors.homeInk,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: title!,
                                ),
                    trailing:
                        actions.isEmpty
                            ? null
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions,
                            ),
                  ),
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}

class _TugetherTitle extends StatelessWidget {
  const _TugetherTitle({this.title});

  final Widget? title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(AppRoutes.home),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            'Tugether',
            style: TextStyle(
              color: AppColors.homeInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      if (title != null) ...[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            '·',
            style: TextStyle(color: AppColors.textFaint, fontSize: 16),
          ),
        ),
        Flexible(
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: AppColors.homeInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: title!,
          ),
        ),
      ],
    ],
  );
}

/// Scrollable page body with the shared side padding (20 on mobile, 24
/// otherwise). Place it inside `AppResponsiveScaffold` to get the centered
/// column.
class AppPageBody extends StatelessWidget {
  const AppPageBody({
    super.key,
    required this.children,
    this.top = AppLayout.bodyTopPadding,
    this.bottom = AppLayout.bodyBottomPadding,
    this.physics,
  });

  final List<Widget> children;
  final double top;
  final double bottom;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final horizontal = AppLayout.horizontalPaddingFor(context.screenType);
    return SingleChildScrollView(
      physics: physics,
      padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Page heading: title and subtitle on the left, an optional action on the
/// right.
class AppPageHeading extends StatelessWidget {
  const AppPageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.homeInk,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: AppSpacing.md), action!],
    ],
  );
}

/// Coral "add" button used in page headings (새 노트, 새 퀴즈, 클래스 추가).
class AppHeadingButton extends StatelessWidget {
  const AppHeadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.55),
      disabledForegroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}
