import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_skeleton.dart';

void main() {
  group('AppSkeleton', () {
    testWidgets('renders basic skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(child: AppSkeleton(width: 100, height: 20)),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.minWidth, 100);
      expect(container.constraints?.minHeight, 20);
    });

    testWidgets('renders circle shape', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppSkeleton(width: 50, height: 50, shape: BoxShape.circle),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.borderRadius, isNull);
    });

    testWidgets('animates opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(child: AppSkeleton(width: 100, height: 20)),
        ),
      );

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);

      final initialOpacity = tester.widget<Opacity>(opacityFinder).opacity;

      // Advance time to allow animation to progress
      await tester.pump(const Duration(milliseconds: 750));

      final midOpacity = tester.widget<Opacity>(opacityFinder).opacity;
      expect(initialOpacity, isNot(equals(midOpacity)));
    });
  });
}
