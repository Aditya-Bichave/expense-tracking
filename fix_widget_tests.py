import os

with open('test/features/groups/presentation/widgets/balances/balance_summary_card_test.dart', 'w') as f:
    f.write("""import 'package:expense_tracker/features/groups/presentation/widgets/balances/balance_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

void main() {
  Widget buildWidget(double netBalance) {
    return MaterialApp(
      theme: AppModeTheme.light(),
      home: Material(
        child: Builder(
          builder: (context) {
            return BalanceSummaryCard(netBalance: netBalance);
          },
        ),
      ),
    );
  }

  group('BalanceSummaryCard', () {
    testWidgets('renders negative balance correctly', (tester) async {
      await tester.pumpWidget(buildWidget(-1500.0));
      expect(find.text('You owe ₹1500.00'), findsOneWidget);
    });

    testWidgets('renders positive balance correctly', (tester) async {
      await tester.pumpWidget(buildWidget(800.0));
      expect(find.text('You are owed ₹800.00'), findsOneWidget);
    });

    testWidgets('renders neutral balance correctly', (tester) async {
      await tester.pumpWidget(buildWidget(0.0));
      expect(find.text('You are all settled up'), findsOneWidget);
    });
  });
}
""")

with open('test/features/groups/presentation/widgets/balances/debt_list_item_test.dart', 'w') as f:
    f.write("""import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/balances/debt_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';

void main() {
  Widget buildWidget({
    required SimplifiedDebt debt,
    required String currentUserId,
  }) {
    return MaterialApp(
      theme: AppModeTheme.light(),
      home: Material(
        child: Builder(
          builder: (context) {
            return DebtListItem(
              debt: debt,
              currentUserId: currentUserId,
              onSettleUp: () {},
              onNudge: () {},
            );
          },
        ),
      ),
    );
  }

  group('DebtListItem', () {
    testWidgets('renders payer view correctly', (tester) async {
      final debt = const SimplifiedDebt(
        fromUserId: 'me',
        toUserId: 'ravi',
        amount: 1500.0,
        fromUserName: 'You',
        toUserName: 'Ravi',
      );

      await tester.pumpWidget(buildWidget(debt: debt, currentUserId: 'me'));

      expect(find.text('You owe Ravi'), findsOneWidget);
      expect(find.text('₹1500.00'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget); // Settle Up button
      expect(find.text('Settle Up'), findsOneWidget);
    });

    testWidgets('renders receiver view correctly', (tester) async {
      final debt = const SimplifiedDebt(
        fromUserId: 'amit',
        toUserId: 'me',
        amount: 800.0,
        fromUserName: 'Amit',
        toUserName: 'You',
      );

      await tester.pumpWidget(buildWidget(debt: debt, currentUserId: 'me'));

      expect(find.text('Amit owes you'), findsOneWidget);
      expect(find.text('₹800.00'), findsOneWidget);
      expect(find.byType(AppIconButton), findsOneWidget); // Nudge button
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('renders third party view correctly', (tester) async {
      final debt = const SimplifiedDebt(
        fromUserId: 'zack',
        toUserId: 'cody',
        amount: 300.0,
        fromUserName: 'Zack',
        toUserName: 'Cody',
      );

      await tester.pumpWidget(buildWidget(debt: debt, currentUserId: 'me'));

      expect(find.text('Zack owes Cody'), findsOneWidget);
      expect(find.text('₹300.00'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      expect(find.byType(AppIconButton), findsNothing);
    });
  });
}
""")
