import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';

/// Whether the desktop class sidebar is open. Closed by default; the menu
/// button in the top bar toggles it, and the choice is app-wide so it follows
/// the user from screen to screen.
final sidebarOpenProvider = StateProvider<bool>((ref) => false);

/// Page frame for every signed-in screen.
///
/// * The [body] sits in a centered column that is at most [maxWidth] wide
///   (780 by default); the rest of the window shows the page background.
/// * A class [menu] is a drawer on mobile and tablet (opened by a menu button
///   in the top bar) and a left sidebar on desktop that the same menu button
///   toggles open and closed. When the screen passes its own [leading]
///   widget, such as a back arrow, the drawer is not attached below desktop;
///   on desktop the toggle sits before that widget.
/// * [bottomBar] is pinned under the body, keeps the column width, and sits
///   above the system safe area.
///
/// Pass either [appBar] or the [title], [leading], [actions] trio; the latter
/// builds an [AppTopBar].
class AppResponsiveScaffold extends ConsumerWidget {
  const AppResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.centerTitle = true,
    this.menu,
    this.menuIcon,
    this.maxWidth = AppLayout.contentMaxWidth,
    this.bottomBar,
    this.bottomNavigationBar,
    this.backgroundColor = AppColors.background,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  /// Class navigation. Drawer below desktop, toggleable sidebar on desktop.
  final Widget? menu;

  /// Icon of the menu button; defaults to [Icons.menu].
  final Widget? menuIcon;

  final double maxWidth;

  /// Content of the pinned bottom bar (for example a `PrimaryButton`).
  final Widget? bottomBar;

  /// Full-width bar below everything, such as the home tab bar.
  final Widget? bottomNavigationBar;

  final Color backgroundColor;

  static const _foldDuration = Duration(milliseconds: 220);

  /// True when [context] is inside a [menu] shown as a drawer.
  static bool isMenuDrawer(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MenuScope>()?.isDrawer ?? false;

  /// True when [context] is inside a [menu] that can be hidden (drawer or
  /// desktop sidebar).
  static bool canHideMenu(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MenuScope>() != null;

  /// Closes the menu when it is a drawer. Does nothing for the sidebar, so
  /// navigating from the sidebar keeps it open.
  static void closeMenu(BuildContext context) {
    if (isMenuDrawer(context)) Navigator.of(context).pop();
  }

  /// Hides the menu: pops a drawer, closes a sidebar.
  static void hideMenu(BuildContext context) {
    context.getInheritedWidgetOfExactType<_MenuScope>()?.onHide();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenType = context.screenType;
    final isDesktop = screenType == ScreenType.desktop;
    final hasMenu = menu != null;
    final hasSidebar = hasMenu && isDesktop;
    final sidebarOpen = hasSidebar && ref.watch(sidebarOpenProvider);
    final hasDrawer = hasMenu && !isDesktop && appBar == null && leading == null;

    Widget? leadingWidget = leading;
    if (appBar == null) {
      if (hasDrawer) {
        leadingWidget = _DrawerButton(icon: menuIcon);
      } else if (hasSidebar) {
        final toggle = IconButton(
          tooltip: sidebarOpen ? '메뉴 닫기' : '메뉴 열기',
          onPressed:
              () =>
                  ref.read(sidebarOpenProvider.notifier).state = !sidebarOpen,
          icon: menuIcon ?? const Icon(Icons.menu),
        );
        leadingWidget =
            leading == null
                ? toggle
                : Row(mainAxisSize: MainAxisSize.min, children: [toggle, leading!]);
      }
    }

    final topBar =
        appBar ??
        AppTopBar(
          leading: leadingWidget,
          title: title,
          actions: actions,
          centerTitle: centerTitle,
        );

    Widget content = _CenteredColumn(maxWidth: maxWidth, child: body);
    if (bottomBar != null) {
      content = Column(
        children: [
          Expanded(child: content),
          _BottomDock(maxWidth: maxWidth, child: bottomBar!),
        ],
      );
    }
    if (hasSidebar) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            collapsed: !sidebarOpen,
            duration: _foldDuration,
            child: _MenuScope(
              isDrawer: false,
              onHide: () => ref.read(sidebarOpenProvider.notifier).state = false,
              child: menu!,
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: topBar,
      drawer:
          hasDrawer
              ? Drawer(
                backgroundColor: AppColors.background,
                child: Builder(
                  builder:
                      (drawerContext) => _MenuScope(
                        isDrawer: true,
                        onHide: () => Navigator.of(drawerContext).pop(),
                        child: menu!,
                      ),
                ),
              )
              : null,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _MenuScope extends InheritedWidget {
  const _MenuScope({
    required this.isDrawer,
    required this.onHide,
    required super.child,
  });

  final bool isDrawer;
  final VoidCallback onHide;

  @override
  bool updateShouldNotify(_MenuScope oldWidget) =>
      isDrawer != oldWidget.isDrawer;
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton({this.icon});

  final Widget? icon;

  @override
  Widget build(BuildContext context) => Builder(
    builder:
        (context) => IconButton(
          tooltip: '클래스 메뉴',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: icon ?? const Icon(Icons.menu),
        ),
  );
}

/// Gives the child the full height and at most [maxWidth], centered.
class _CenteredColumn extends StatelessWidget {
  const _CenteredColumn({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox.expand(child: child),
    ),
  );
}

/// Desktop sidebar that folds to zero width. The menu keeps its full width
/// while folding so its contents slide away instead of squeezing, and is
/// dropped from the tree once the fold has finished.
class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.collapsed,
    required this.duration,
    required this.child,
  });

  final bool collapsed;
  final Duration duration;
  final Widget child;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  late bool _showChild = !widget.collapsed;

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.collapsed && !_showChild) setState(() => _showChild = true);
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: widget.duration,
    curve: Curves.easeOutCubic,
    width: widget.collapsed ? 0 : AppLayout.sidebarWidth,
    onEnd: () {
      if (widget.collapsed && mounted) setState(() => _showChild = false);
    },
    child:
        _showChild
            ? ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: AppLayout.sidebarWidth,
                maxWidth: AppLayout.sidebarWidth,
                child: Material(
                  color: AppColors.surface,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.homeDivider),
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            )
            : null,
  );
}

/// Full-width surface whose content keeps the column width.
class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.homeDivider)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalPaddingFor(context.screenType),
                vertical: AppSpacing.sm,
              ),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    ),
  );
}
