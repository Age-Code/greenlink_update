import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/theme/app_scroll_behavior.dart';

void main() {
  testWidgets('desktop scroll views get no scrollbar', (tester) async {
    // Must be reset inside the test body; the binding checks it before
    // tearDowns run.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    Widget app(ScrollBehavior behavior) => MaterialApp(
      scrollBehavior: behavior,
      home: Scaffold(
        body: ListView(
          children: [for (var i = 0; i < 60; i++) Text('row $i')],
        ),
      ),
    );

    final anyScrollbar = find.byWidgetPredicate(
      (widget) => widget is Scrollbar || widget is RawScrollbar,
    );

    await tester.pumpWidget(app(const MaterialScrollBehavior()));
    expect(anyScrollbar, findsWidgets);

    await tester.pumpWidget(app(const AppScrollBehavior()));
    expect(anyScrollbar, findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(anyScrollbar, findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
