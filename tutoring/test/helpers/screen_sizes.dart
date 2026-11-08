import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Window sizes every screen must render without overflow:
/// phone 390x844, tablet 1024x1366, desktop 1440x900.
abstract final class TestScreenSizes {
  static const phone = Size(390, 844);
  static const tablet = Size(1024, 1366);
  static const desktop = Size(1440, 900);

  /// Narrowest tablet; catches two-column layouts that are too tight.
  static const narrowTablet = Size(600, 1024);

  static const all = [phone, tablet, desktop];
  static const allWithNarrowTablet = [phone, narrowTablet, tablet, desktop];
}

extension ScreenSizeTester on WidgetTester {
  /// Resizes the test window to [size] (1 logical pixel = 1 physical pixel)
  /// and restores it when the test ends.
  void setScreenSize(Size size) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  }

  /// Pumps [app] at [size] and lets asset loads and streams settle. Screens
  /// that mount their content after a first async load (profile, class) need
  /// the extra frames for their own streams to arrive.
  Future<void> pumpAtSize(Widget app, Size size) async {
    setScreenSize(size);
    await runAsync(() async {
      await pumpWidget(app);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    for (var frame = 0; frame < 4; frame++) {
      await pump(const Duration(milliseconds: 100));
    }
  }
}

/// Runs one widget test per size in [sizes]. The test fails when layout
/// throws, which is how a RenderFlex overflow surfaces.
void testAtScreenSizes(
  String description,
  Widget Function() build, {
  List<Size> sizes = TestScreenSizes.all,
  Future<void> Function(WidgetTester tester, Size size)? verify,
}) {
  for (final size in sizes) {
    testWidgets(
      '$description · ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.pumpAtSize(build(), size);
        expect(tester.takeException(), isNull);
        if (verify != null) await verify(tester, size);
      },
    );
  }
}
