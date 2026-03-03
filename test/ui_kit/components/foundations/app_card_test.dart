import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double? elevation,
    bool glass = false,
    AppModeTheme? modeTheme,
  }) {
    return MaterialApp(
      home: Material(
        child: Builder(
          builder: (context) {
            Widget content = AppCard(
              onTap: onTap,
              padding: padding,
              margin: margin,
              color: color,
              elevation: elevation,
              glass: glass,
              child: child,
            );

            if (modeTheme != null) {
              return Theme(
                data: ThemeData().copyWith(extensions: [modeTheme]),
                child: Builder(
                  builder: (innerContext) {
                    return AppCard(
                      onTap: onTap,
                      padding: padding,
                      margin: margin,
                      color: color,
                      elevation: elevation,
                      glass: glass,
                      child: child,
                    );
                  },
                ),
              );
            }
            return content;
          },
        ),
      ),
    );
  }

  group('AppCard', () {
    testWidgets('renders child in Card by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(child: const Text('Card Content')),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders glass effect when requested', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(glass: true, child: const Text('Glass Content')),
      );

      expect(find.text('Glass Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('handles onTap in standard card', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          onTap: () => tapped = true,
          child: const Text('Tap Me'),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, true);
    });

    testWidgets('handles onTap in glass card', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          glass: true,
          onTap: () => tapped = true,
          child: const Text('Tap Me Glass'),
        ),
      );

      await tester.tap(find.text('Tap Me Glass'));
      expect(tapped, true);
    });
  });
}
