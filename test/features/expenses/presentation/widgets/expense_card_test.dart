import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Create a wrapper to provide context.kit
class TestWrapper extends StatelessWidget {
  final Widget child;
  const TestWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: child));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    Intl.defaultLocale = 'en_US';
  });

  final category = Category(
    id: 'food',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: false,
  );

  final expense = Expense(
    id: '1',
    amount: 50.0,
    currency: 'USD',
    // Use a fixed time to ensure time formatting is consistent if displayed
    date: DateTime(2023, 10, 26, 12, 0),
    title: 'Lunch',
    accountId: 'acc1',
    category: category,
  );

  testWidgets('ExpenseCard renders correctly', (tester) async {
    await tester.pumpWidget(
      TestWrapper(
        child: ExpenseCard(
          expense: expense,
          accountName: 'Cash',
          currencySymbol: '\$',
          onCardTap: (_) {},
        ),
      ),
    );

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('\$50.00'), findsOneWidget);
    expect(find.text('Acc: Cash'), findsOneWidget);
    // DateFormatter.formatDateTime uses yMMMd().add_jm() -> "Oct 26, 2023 12:00 PM"
    // Just find "Oct 26, 2023" as substring or check full string.
    // The previous failure said "Oct 26, 2023" not found.
    // Let's use `find.textContaining`.
    expect(find.textContaining('Oct 26, 2023'), findsOneWidget);
  });

  testWidgets('ExpenseCard handles tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      TestWrapper(
        child: ExpenseCard(
          expense: expense,
          accountName: 'Cash',
          currencySymbol: '\$',
          onCardTap: (_) {
            tapped = true;
          },
        ),
      ),
    );

    await tester.tap(find.byType(ExpenseCard));
    expect(tapped, true);
  });
}
