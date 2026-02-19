import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/pages/add_edit_recurring_rule_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAddEditRecurringRuleBloc
    extends MockBloc<AddEditRecurringRuleEvent, AddEditRecurringRuleState>
    implements AddEditRecurringRuleBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockAddEditRecurringRuleBloc mockBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockCategoryManagementBloc mockCategoryManagementBloc;
  late MockAccountListBloc mockAccountListBloc;

  setUp(() {
    sl.reset();
    mockBloc = MockAddEditRecurringRuleBloc();
    sl.registerFactory<AddEditRecurringRuleBloc>(() => mockBloc);

    mockSettingsBloc = MockSettingsBloc();
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    mockAccountListBloc = MockAccountListBloc();
  });

  tearDown(() {
    sl.reset();
  });

  const tCategory = Category(
    id: 'cat1',
    name: 'Test Category',
    iconName: 'icon',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tAccount = AssetAccount(
    id: 'acc1',
    name: 'Test Account',
    type: AssetType.cash,
    initialBalance: 0,
    currentBalance: 0,
  );

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AddEditRecurringRuleBloc>.value(value: mockBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<CategoryManagementBloc>.value(
          value: mockCategoryManagementBloc,
        ),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddEditRecurringRuleView(),
      ),
    );
  }

  testWidgets('AddEditRecurringRulePage renders correctly', (tester) async {
    when(
      () => mockBloc.state,
    ).thenReturn(AddEditRecurringRuleState(startDate: DateTime.now()));
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockCategoryManagementBloc.state).thenReturn(
      const CategoryManagementState(predefinedExpenseCategories: [tCategory]),
    );
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(AccountListLoaded(accounts: [tAccount]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    debugPrint(
      'Found AddEditRecurringRuleView: ${find.byType(AddEditRecurringRuleView).evaluate().length}',
    );
    verify(() => mockBloc.state).called(greaterThan(0));

    expect(find.text('Add Recurring Rule'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Select Account'), findsOneWidget);
  });

  testWidgets('AddEditRecurringRulePage toggles transaction type', (
    tester,
  ) async {
    when(
      () => mockBloc.state,
    ).thenReturn(AddEditRecurringRuleState(startDate: DateTime.now()));
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockCategoryManagementBloc.state,
    ).thenReturn(const CategoryManagementState());
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Income
    await tester.tap(find.text('Income'));
    verify(
      () => mockBloc.add(const TransactionTypeChanged(TransactionType.income)),
    ).called(1);
  });
}
