import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/theme/app_theme.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';

import 'helpers/screen_sizes.dart';

void main() {
  group('AppBreakpoints', () {
    test('splits widths into mobile, tablet and desktop', () {
      expect(AppBreakpoints.of(0), ScreenType.mobile);
      expect(AppBreakpoints.of(599), ScreenType.mobile);
      expect(AppBreakpoints.of(600), ScreenType.tablet);
      expect(AppBreakpoints.of(1199), ScreenType.tablet);
      expect(AppBreakpoints.of(1200), ScreenType.desktop);
      expect(AppBreakpoints.of(1440), ScreenType.desktop);
    });
  });

  group('AppResponsiveScaffold', () {
    const bodyKey = Key('body');
    const barKey = Key('bar');

    Widget app({Widget? leading, Widget? menu, Widget? bottomBar}) =>
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: AppResponsiveScaffold(
              title: const Text('제목'),
              leading: leading,
              menu: menu,
              bottomBar: bottomBar,
              body: const SizedBox.expand(key: bodyKey),
            ),
          ),
        );

    Widget menu() => Builder(
      builder:
          (context) => Column(
            children: [
              const Text('menu'),
              TextButton(
                onPressed: () => AppResponsiveScaffold.closeMenu(context),
                child: const Text('close'),
              ),
              TextButton(
                onPressed: () => AppResponsiveScaffold.hideMenu(context),
                child: const Text('hide'),
              ),
            ],
          ),
    );

    testWidgets('phone: menu is a drawer behind a menu button', (
      tester,
    ) async {
      tester.setScreenSize(TestScreenSizes.phone);
      await tester.pumpWidget(app(menu: menu()));

      expect(find.text('menu'), findsNothing);
      expect(tester.getSize(find.byKey(bodyKey)).width, 390);

      await tester.tap(find.byTooltip('클래스 메뉴'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsOneWidget);
      expect(AppResponsiveScaffold.isMenuDrawer(
        tester.element(find.text('menu')),
      ), isTrue);

      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsNothing);
    });

    testWidgets('tablet: body is a centered 780 column, menu is a drawer', (
      tester,
    ) async {
      tester.setScreenSize(TestScreenSizes.tablet);
      await tester.pumpWidget(app(menu: menu()));

      expect(find.text('menu'), findsNothing);
      expect(find.byTooltip('클래스 메뉴'), findsOneWidget);
      expect(tester.getSize(find.byKey(bodyKey)).width, 780);
      expect(tester.getTopLeft(find.byKey(bodyKey)).dx, (1024 - 780) / 2);
    });

    testWidgets('desktop: the sidebar starts closed and the menu button '
        'toggles it; the column recenters each time', (tester) async {
      tester.setScreenSize(TestScreenSizes.desktop);
      await tester.pumpWidget(app(menu: menu()));

      expect(find.text('menu'), findsNothing);
      expect(find.byTooltip('메뉴 열기'), findsOneWidget);
      expect(tester.getSize(find.byKey(bodyKey)).width, 780);
      expect(tester.getTopLeft(find.byKey(bodyKey)).dx, (1440 - 780) / 2);

      await tester.tap(find.byTooltip('메뉴 열기'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsOneWidget);
      expect(find.byTooltip('메뉴 닫기'), findsOneWidget);
      expect(AppResponsiveScaffold.isMenuDrawer(
        tester.element(find.text('menu')),
      ), isFalse);
      expect(
        tester.getTopLeft(find.byKey(bodyKey)).dx,
        AppLayout.sidebarWidth + (1440 - AppLayout.sidebarWidth - 780) / 2,
      );

      // closeMenu (used after navigation) must not close the sidebar.
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsOneWidget);

      await tester.tap(find.byTooltip('메뉴 닫기'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsNothing);
      expect(tester.getTopLeft(find.byKey(bodyKey)).dx, (1440 - 780) / 2);
    });

    testWidgets('desktop: the open/closed choice is shared by every scaffold, '
        'also next to a back arrow', (tester) async {
      tester.setScreenSize(TestScreenSizes.desktop);
      await tester.pumpWidget(app(menu: menu()));
      await tester.tap(find.byTooltip('메뉴 열기'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsOneWidget);

      await tester.pumpWidget(app(menu: menu(), leading: const BackButton()));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsOneWidget);
      expect(find.byTooltip('메뉴 닫기'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.text('hide'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsNothing);
      expect(find.byTooltip('메뉴 열기'), findsOneWidget);
    });

    testWidgets('phone: hideMenu closes the drawer', (tester) async {
      tester.setScreenSize(TestScreenSizes.phone);
      await tester.pumpWidget(app(menu: menu()));
      await tester.tap(find.byTooltip('클래스 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('hide'));
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsNothing);
    });

    testWidgets('a screen with its own leading keeps the drawer off but '
        'still gets the desktop toggle', (tester) async {
      tester.setScreenSize(TestScreenSizes.phone);
      await tester.pumpWidget(
        app(menu: menu(), leading: const BackButton()),
      );
      expect(find.byTooltip('클래스 메뉴'), findsNothing);
      expect(find.byType(Drawer), findsNothing);

      tester.setScreenSize(TestScreenSizes.desktop);
      await tester.pumpWidget(
        app(menu: menu(), leading: const BackButton()),
      );
      expect(find.byTooltip('메뉴 열기'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('bottom bar keeps the column width and side padding', (
      tester,
    ) async {
      tester.setScreenSize(TestScreenSizes.phone);
      await tester.pumpWidget(
        app(bottomBar: const SizedBox(key: barKey, height: 48)),
      );
      expect(
        tester.getSize(find.byKey(barKey)).width,
        390 - 2 * AppLayout.mobileHorizontalPadding,
      );

      tester.setScreenSize(TestScreenSizes.desktop);
      await tester.pumpWidget(
        app(bottomBar: const SizedBox(key: barKey, height: 48)),
      );
      expect(
        tester.getSize(find.byKey(barKey)).width,
        780 - 2 * AppLayout.horizontalPadding,
      );
      expect(tester.getBottomLeft(find.byKey(barKey)).dy, lessThanOrEqualTo(900));
    });
  });
}
