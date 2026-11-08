import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/theme/app_theme.dart';

void main() {
  testWidgets('a pushed page is fully in place on its first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => const Scaffold(
                                body: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text('second'),
                                ),
                              ),
                        ),
                      ),
                  child: const Text('go'),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    // With the default slide, the new page would still sit far to the right.
    expect(tester.getTopLeft(find.text('second')), Offset.zero);
  });
}
