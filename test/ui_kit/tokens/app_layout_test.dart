import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_layout.dart';

void main() {
  group('AppLayout', () {
    test('static constants have correct values', () {
      expect(AppLayout.mobileBreakpoint, 600);
      expect(AppLayout.tabletBreakpoint, 900);
      expect(AppLayout.desktopBreakpoint, 1200);
      expect(AppLayout.maxContentWidth, 1000);
      expect(AppLayout.maxTextWidth, 600);
    });

    test('contentConstraints returns correct constraints', () {
      final constraints = AppLayout.contentConstraints;
      expect(constraints.maxWidth, 1000);
    });

    testWidgets('isMobile returns true on small screens', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppLayout.isMobile(context), isTrue);
              expect(AppLayout.isTablet(context), isFalse);
              expect(AppLayout.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true on medium screens', (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppLayout.isMobile(context), isFalse);
              expect(AppLayout.isTablet(context), isTrue);
              expect(AppLayout.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true on large screens', (tester) async {
      tester.view.physicalSize = const Size(1300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppLayout.isMobile(context), isFalse);
              expect(AppLayout.isTablet(context), isFalse);
              expect(AppLayout.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
