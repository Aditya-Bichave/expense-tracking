import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tIncome = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    category: const Category(
      id: 'cat1',
      name: 'Job',
      iconName: 'work',
      colorHex: '#000000',
      type: CategoryType.income,
      isCustom: false,
    ),
    notes: 'Monthly salary',
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
    isRecurring: true,
  );

  const tAccount = AssetAccount(
    id: 'acc1',
    name: 'Main Bank',
    type: AssetType.bank,
    initialBalance: 0,
    currentBalance: 0,
  );

  group('IncomeCard', () {
    testWidgets('renders title, amount, and date', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(income: tIncome),
        ),
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        accountListState: const AccountListLoaded(accounts: [tAccount]),
      );

      expect(find.text('Salary'), findsOneWidget); // Title
      expect(find.text('\$5,000.00'), findsOneWidget); // Amount formatted
      expect(find.textContaining('2023'), findsOneWidget); // Date formatted
    });

    testWidgets('renders account name when account exists', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(income: tIncome),
        ),
        accountListState: const AccountListLoaded(accounts: [tAccount]),
      );

      expect(find.text('Acc: Main Bank'), findsOneWidget);
    });

    testWidgets('renders "Deleted" when account is missing', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(income: tIncome),
        ),
        accountListState: const AccountListLoaded(accounts: []),
      );

      expect(find.text('Acc: Deleted'), findsOneWidget);
    });

    testWidgets('renders "Error" when account list is error', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(income: tIncome),
        ),
        accountListState: const AccountListError('Error'),
      );

      expect(find.text('Acc: Error'), findsOneWidget);
    });

    testWidgets('calls onCardTap when tapped', (tester) async {
      bool tapped = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(
            income: tIncome,
            onCardTap: (_) => tapped = true,
          ),
        ),
        accountListState: const AccountListLoaded(accounts: [tAccount]),
      );

      await tester.tap(find.byType(IncomeCard));
      expect(tapped, true);
    });

    testWidgets('calls onChangeCategoryRequest when categorized status tapped',
        (tester) async {
      bool requested = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(
            income: tIncome,
            onChangeCategoryRequest: (_) => requested = true,
          ),
        ),
        accountListState: const AccountListLoaded(accounts: [tAccount]),
      );

      await tester.tap(
          find.byKey(const ValueKey('inkwell_categorization_change_categorized')));
      expect(requested, true);
    });

    testWidgets('shows categorize button when uncategorized', (tester) async {
      final tUncategorizedIncome = tIncome.copyWith(
        status: CategorizationStatus.uncategorized,
        categoryOrNull: () => null,
      );

      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: IncomeCard(
            income: tUncategorizedIncome,
          ),
        ),
        accountListState: const AccountListLoaded(accounts: [tAccount]),
      );

      expect(find.byKey(const ValueKey('button_categorization_categorize')),
          findsOneWidget);
      expect(find.text('Categorize'), findsOneWidget);
    });
  });
}
