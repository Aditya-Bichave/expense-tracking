// test/ui_coverage_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_form.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_form.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';

// Mocks
class MockAddEditTransactionBloc
    extends MockBloc<AddEditTransactionEvent, AddEditTransactionState>
    implements AddEditTransactionBloc {}

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState>
    implements GoalListBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late MockTransactionListBloc mockTransactionListBloc;
  late MockBudgetListBloc mockBudgetListBloc;
  late MockGoalListBloc mockGoalListBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockAccountListBloc mockAccountListBloc;
  late MockCategoryManagementBloc mockCategoryManagementBloc;
  late MockAddEditTransactionBloc mockAddEditTransactionBloc;

  setUpAll(() {
    registerFallbackValue(const LoadTransactions());
    registerFallbackValue(const LoadBudgets());
    registerFallbackValue(const LoadGoals());
    registerFallbackValue(const LoadSettings());
    registerFallbackValue(const LoadCategories());
    registerFallbackValue(
      const TransactionTypeChanged(TransactionType.expense),
    );
  });

  setUp(() {
    mockTransactionListBloc = MockTransactionListBloc();
    mockBudgetListBloc = MockBudgetListBloc();
    mockGoalListBloc = MockGoalListBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockAccountListBloc = MockAccountListBloc();
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    mockAddEditTransactionBloc = MockAddEditTransactionBloc();

    // Reset Service Locator
    sl.reset();
    sl.registerFactory<TransactionListBloc>(() => mockTransactionListBloc);
    sl.registerFactory<BudgetListBloc>(() => mockBudgetListBloc);
    sl.registerFactory<GoalListBloc>(() => mockGoalListBloc);
    sl.registerFactory<SettingsBloc>(() => mockSettingsBloc);
    sl.registerFactory<AccountListBloc>(() => mockAccountListBloc);
    sl.registerFactory<CategoryManagementBloc>(
      () => mockCategoryManagementBloc,
    );
    sl.registerFactory<AddEditTransactionBloc>(
      () => mockAddEditTransactionBloc,
    );
  });

  Widget createWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
        BlocProvider<CategoryManagementBloc>.value(
          value: mockCategoryManagementBloc,
        ),
        BlocProvider<AddEditTransactionBloc>.value(
          value: mockAddEditTransactionBloc,
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('UI Coverage Smoke Tests', () {
    testWidgets('TransactionListPage renders', (tester) async {
      when(
        () => mockTransactionListBloc.state,
      ).thenReturn(const TransactionListState());
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListInitial());

      await tester.pumpWidget(createWidget(const TransactionListPage()));
      expect(find.byType(TransactionListPage), findsOneWidget);
    });

    testWidgets('BudgetsSubTab renders', (tester) async {
      when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState());
      await tester.pumpWidget(createWidget(const BudgetsSubTab()));
      expect(find.byType(BudgetsSubTab), findsOneWidget);
    });

    testWidgets('GoalsSubTab renders', (tester) async {
      when(() => mockGoalListBloc.state).thenReturn(const GoalListState());
      await tester.pumpWidget(createWidget(const GoalsSubTab()));
      expect(find.byType(GoalsSubTab), findsOneWidget);
    });

    testWidgets('ReportPageWrapper renders', (tester) async {
      await tester.pumpWidget(
        createWidget(const ReportPageWrapper(title: 'Test', body: SizedBox())),
      );
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('TransactionForm renders', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      when(
        () => mockCategoryManagementBloc.state,
      ).thenReturn(const CategoryManagementState());
      when(
        () => mockAddEditTransactionBloc.state,
      ).thenReturn(const AddEditTransactionState());
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListInitial());

      await tester.pumpWidget(
        createWidget(
          Material(
            child: TransactionForm(
              initialType: TransactionType.expense,
              onSubmit:
                  (type, title, amount, date, category, accountId, notes) {},
            ),
          ),
        ),
      );
      expect(find.byType(TransactionForm), findsOneWidget);
    });

    testWidgets('BudgetForm renders', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

      await tester.pumpWidget(
        createWidget(
          Material(
            child: BudgetForm(
              availableCategories: const [],
              onSubmit:
                  (name, type, amount, period, start, end, cats, notes) {},
            ),
          ),
        ),
      );
      expect(find.byType(BudgetForm), findsOneWidget);
    });

    testWidgets('AccountForm renders', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

      await tester.pumpWidget(
        createWidget(
          Material(child: AccountForm(onSubmit: (name, type, balance) {})),
        ),
      );
      expect(find.byType(AccountForm), findsOneWidget);
    });
  });
}
