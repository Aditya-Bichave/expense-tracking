import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_switch.dart';

void main() {
  Widget buildTestWidget({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return MaterialApp(
      home: Material(
        child: AppSwitch(value: value, onChanged: onChanged),
      ),
    );
  }

  group('AppSwitch', () {
    testWidgets('renders off', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: false, onChanged: (_) {}));

      final cupertinoSwitch = tester.widget<CupertinoSwitch>(
        find.byType(CupertinoSwitch),
      );
      expect(cupertinoSwitch.value, false);
    });

    testWidgets('renders on', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: true, onChanged: (_) {}));

      final cupertinoSwitch = tester.widget<CupertinoSwitch>(
        find.byType(CupertinoSwitch),
      );
      expect(cupertinoSwitch.value, true);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        buildTestWidget(value: false, onChanged: (val) => changedValue = val),
      );

      await tester.tap(find.byType(CupertinoSwitch));
      expect(changedValue, true);
    });

    testWidgets('renders disabled when onChanged is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: false, onChanged: null));

      final cupertinoSwitch = tester.widget<CupertinoSwitch>(
        find.byType(CupertinoSwitch),
      );
      expect(cupertinoSwitch.onChanged, null);
    });
  });
}
