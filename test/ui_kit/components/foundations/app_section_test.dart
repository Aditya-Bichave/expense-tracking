import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppSection', () {
    testWidgets('renders section title and content', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Scaffold(
          body: AppSection(
            title: 'Section Title',
            child: Text('Section Content'),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Section Content'), findsOneWidget);
    });

    testWidgets('renders action widget if provided', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: AppSection(
            title: 'Section Title',
            action: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
            child: const Text('Section Content'),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
