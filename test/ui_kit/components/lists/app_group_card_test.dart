import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_group_card.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppGroupCard', () {
    testWidgets('renders basic group card with children', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppGroupCard(
          title: 'Group Title',
          children: const [Text('Child 1'), Text('Child 2')],
        ),
      );

      expect(find.text('Group Title'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });

    testWidgets('renders action if provided', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppGroupCard(
          title: 'Group',
          action: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
          children: const [Text('Child')],
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
