import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppGap', () {
    testWidgets('renders horizontal gap', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Builder(
          builder: (context) => Row(
            children: [
              const Text('A'),
              AppGap.xs(context),
              AppGap.sm(context),
              AppGap.md(context),
              AppGap.lg(context),
              AppGap.xl(context),
              const Text('B'),
            ],
          ),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders vertical gap', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Builder(
          builder: (context) => Column(
            children: [
              const Text('A'),
              AppGap.xs(context),
              AppGap.sm(context),
              AppGap.md(context),
              AppGap.lg(context),
              AppGap.xl(context),
              const Text('B'),
            ],
          ),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders custom size gap', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Row(children: const [Text('A'), AppGap(20.0), Text('B')]),
      );
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
