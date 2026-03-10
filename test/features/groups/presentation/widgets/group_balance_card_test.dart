import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/group_balance_card.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('GroupBalanceCard Tests', () {
    testWidgets('renders "You are settled up" when netBalance is 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const GroupBalanceCard(netBalance: 0.0, key: Key('test')),
        ),
      );
      expect(find.text('You are settled up'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders "You are owed" when netBalance is positive', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const GroupBalanceCard(netBalance: 12.50, key: Key('test')),
        ),
      );
      expect(find.text('You are owed \$12.50'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('renders "You owe" when netBalance is negative', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const GroupBalanceCard(netBalance: -25.75, key: Key('test')),
        ),
      );
      expect(find.text('You owe \$25.75'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
