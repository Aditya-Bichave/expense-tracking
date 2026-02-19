import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/recurring_rule_list_item.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('RecurringRuleListItem renders correctly', (tester) async {
    final rule = RecurringRule(
      id: '1',
      description: 'Test Rule',
      amount: 100.0,
      transactionType: TransactionType.expense,
      accountId: 'acc1',
      categoryId: 'cat1',
      frequency: Frequency.monthly,
      interval: 1,
      startDate: DateTime(2023, 1, 1),
      endConditionType: EndConditionType.never,
      status: RuleStatus.active,
      nextOccurrenceDate: DateTime(2023, 2, 1),
      occurrencesGenerated: 0,
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurringRuleListItem(
            rule: rule,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Verify description
    expect(find.text('Test Rule'), findsOneWidget);

    // Verify amount
    expect(find.text('-100.00'), findsOneWidget);

    // Verify next date
    final formattedDate = DateFormat.yMd().format(rule.nextOccurrenceDate);
    expect(find.textContaining('Next: $formattedDate'), findsOneWidget);
    expect(find.textContaining('Repeats monthly'), findsOneWidget);

    // Verify tap
    await tester.tap(find.byType(RecurringRuleListItem));
    expect(tapped, isTrue);
  });

  testWidgets('RecurringRuleListItem renders paused icon when paused', (tester) async {
     final rule = RecurringRule(
      id: '1',
      description: 'Test Rule',
      amount: 100.0,
      transactionType: TransactionType.expense,
      accountId: 'acc1',
      categoryId: 'cat1',
      frequency: Frequency.monthly,
      interval: 1,
      startDate: DateTime(2023, 1, 1),
      endConditionType: EndConditionType.never,
      status: RuleStatus.paused,
      nextOccurrenceDate: DateTime(2023, 2, 1),
      occurrencesGenerated: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurringRuleListItem(
            rule: rule,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
  });
}
