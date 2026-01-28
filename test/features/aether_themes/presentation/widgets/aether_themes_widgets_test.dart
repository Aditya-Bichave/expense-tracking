import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aether Themes Widgets', () {
    testWidgets('FinancialGardenWidget renders placeholder text',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FinancialGardenWidget()));

      expect(find.textContaining('Financial Garden Dashboard'), findsOneWidget);
      expect(find.textContaining('(Coming Soon!)'), findsOneWidget);
    });

    testWidgets('PersonalConstellationWidget renders placeholder text',
        (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: PersonalConstellationWidget()));

      expect(find.textContaining('Personal Constellation Dashboard'),
          findsOneWidget);
      expect(find.textContaining('(Coming Soon!)'), findsOneWidget);
    });
  });
}
