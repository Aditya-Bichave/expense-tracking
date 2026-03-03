import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_segmented_control.dart';

void main() {
  Widget buildTestWidget({
    required Map<String, Widget> children,
    required String? groupValue,
    required ValueChanged<String?> onValueChanged,
  }) {
    return MaterialApp(
      home: Material(
        child: AppSegmentedControl<String>(
          children: children,
          groupValue: groupValue,
          onValueChanged: onValueChanged,
        ),
      ),
    );
  }

  group('AppSegmentedControl', () {
    final Map<String, Widget> testChildren = {
      '1': const Text('Option 1'),
      '2': const Text('Option 2'),
    };

    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          children: testChildren,
          groupValue: '1',
          onValueChanged: (_) {},
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(
        find.byType(CupertinoSlidingSegmentedControl<String>),
        findsOneWidget,
      );
    });

    testWidgets('passes correct groupValue', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          children: testChildren,
          groupValue: '2',
          onValueChanged: (_) {},
        ),
      );

      final control = tester.widget<CupertinoSlidingSegmentedControl<String>>(
        find.byType(CupertinoSlidingSegmentedControl<String>),
      );
      expect(control.groupValue, '2');
    });

    testWidgets('calls onValueChanged when an option is tapped', (
      tester,
    ) async {
      String? changedValue;
      await tester.pumpWidget(
        buildTestWidget(
          children: testChildren,
          groupValue: '1',
          onValueChanged: (val) => changedValue = val,
        ),
      );

      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();

      expect(changedValue, '2');
    });
  });
}
