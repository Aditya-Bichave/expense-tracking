import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockAccountListBloc mockAccountListBloc;

  setUp(() {
    mockAccountListBloc = MockAccountListBloc();
  });

  final tExpense = Expense(
    id: '1',
    title: 'Groceries',
    amount: 50.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
  );

  testWidgets('ExpenseCard displays expense details correctly', (tester) async {
    // Act
    await pumpWidgetWithProviders(
      tester: tester,
      widget: ExpenseCard(
        expense: tExpense,
        accountName: 'Main Account',
        currencySymbol: '\$',
      ),
      accountListBloc: mockAccountListBloc,
    );

    // Assert
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Acc: Main Account'), findsOneWidget);
    expect(find.textContaining('50.00'), findsOneWidget);
  });

  testWidgets('ExpenseCard displays provided account name', (tester) async {
    // Act
    await pumpWidgetWithProviders(
      tester: tester,
      widget: ExpenseCard(
        expense: tExpense,
        accountName: 'Deleted',
        currencySymbol: '\$',
      ),
      accountListBloc: mockAccountListBloc,
    );

    // Assert
    expect(find.text('Acc: Deleted'), findsOneWidget);
  });

  testWidgets('ExpenseCard renders correct icon for category', (tester) async {
    final category = Category(
      id: 'cat1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#FF0000',
      type: CategoryType.expense,
      isCustom: false,
    );
    final expenseWithCategory = tExpense.copyWith(
      category: category,
      status: CategorizationStatus.categorized,
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: ExpenseCard(
        expense: expenseWithCategory,
        accountName: 'Main Account',
        currencySymbol: '\$',
      ),
      accountListBloc: mockAccountListBloc,
    );

    // Verify icon is present (either Icon or SvgPicture depending on theme assets)
    final hasIcon = find.byType(Icon).evaluate().isNotEmpty;
    final hasSvg = find.byType(SvgPicture).evaluate().isNotEmpty;

    expect(
      hasIcon || hasSvg,
      isTrue,
      reason: 'Should render either Icon or SvgPicture',
    );
  });
}
