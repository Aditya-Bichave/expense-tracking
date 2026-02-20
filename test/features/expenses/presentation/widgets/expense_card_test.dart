import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
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

  const tAccount = AssetAccount(
    id: 'acc1',
    name: 'Main Account',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 950,
  );

  testWidgets('ExpenseCard displays expense details correctly', (tester) async {
    // Arrange

    // Act
    await pumpWidgetWithProviders(
      tester: tester,
      widget: ExpenseCard(
        expense: tExpense,
        accountName: 'Main Account',
      ),
    );

    // Assert
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Acc: Main Account'), findsOneWidget);
    expect(find.textContaining('50.00'), findsOneWidget);
  });

  testWidgets('ExpenseCard handles missing account gracefully', (tester) async {
    // Arrange

    // Act
    await pumpWidgetWithProviders(
      tester: tester,
      widget: ExpenseCard(
        expense: tExpense,
        accountName: 'Deleted',
      ),
    );

    // Assert
    expect(find.text('Acc: Deleted'), findsOneWidget);
  });
}
