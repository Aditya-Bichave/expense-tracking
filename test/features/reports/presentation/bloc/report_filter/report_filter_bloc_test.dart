import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockGetAssetAccountsUseCase extends Mock
    implements GetAssetAccountsUseCase {}

class MockGetBudgetsUseCase extends Mock implements GetBudgetsUseCase {}

class MockGetGoalsUseCase extends Mock implements GetGoalsUseCase {}

void main() {
  late ReportFilterBloc bloc;
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockGetAssetAccountsUseCase mockGetAssetAccountsUseCase;
  late MockGetBudgetsUseCase mockGetBudgetsUseCase;
  late MockGetGoalsUseCase mockGetGoalsUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockGetAssetAccountsUseCase = MockGetAssetAccountsUseCase();
    mockGetBudgetsUseCase = MockGetBudgetsUseCase();
    mockGetGoalsUseCase = MockGetGoalsUseCase();

    // Default mocks to return empty lists
    when(
      () => mockGetCategoriesUseCase(any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockGetAssetAccountsUseCase(any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockGetBudgetsUseCase(any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockGetGoalsUseCase(any()),
    ).thenAnswer((_) async => const Right([]));

    // We do NOT initialize bloc here because it triggers LoadFilterOptions immediately
  });

  final tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '0xFFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tAccount = AssetAccount(
    id: '1',
    name: 'Bank',
    initialBalance: 100,
    currentBalance: 100,
    type: AssetType.bank,
  );

  final tBudget = Budget(
    id: '1',
    name: 'Budget',
    targetAmount: 100,
    type: BudgetType.overall,
    period: BudgetPeriodType.oneTime,
    createdAt: DateTime.now(),
  );

  final tGoal = Goal(
    id: '1',
    name: 'Goal',
    targetAmount: 100,
    totalSaved: 0,
    targetDate: DateTime.now(),
    iconName: 'icon',
    status: GoalStatus.active,
    createdAt: DateTime.now(),
  );

  blocTest<ReportFilterBloc, ReportFilterState>(
    'emits [loading, loaded] when initialized and options load successfully',
    build: () {
      when(
        () => mockGetCategoriesUseCase(any()),
      ).thenAnswer((_) async => Right([tCategory]));
      when(
        () => mockGetAssetAccountsUseCase(any()),
      ).thenAnswer((_) async => Right([tAccount]));
      when(
        () => mockGetBudgetsUseCase(any()),
      ).thenAnswer((_) async => Right([tBudget]));
      when(
        () => mockGetGoalsUseCase(any()),
      ).thenAnswer((_) async => Right([tGoal]));

      return ReportFilterBloc(
        categoryRepository: mockGetCategoriesUseCase,
        accountRepository: mockGetAssetAccountsUseCase,
        budgetRepository: mockGetBudgetsUseCase,
        goalRepository: mockGetGoalsUseCase,
      );
    },
    // The event LoadFilterOptions is added in constructor, so we don't add it here
    expect: () => [
      isA<ReportFilterState>().having(
        (s) => s.optionsStatus,
        'status',
        FilterOptionsStatus.loading,
      ),
      isA<ReportFilterState>()
          .having((s) => s.optionsStatus, 'status', FilterOptionsStatus.loaded)
          .having((s) => s.availableCategories, 'categories', [tCategory])
          .having((s) => s.availableAccounts, 'accounts', [tAccount])
          .having((s) => s.availableBudgets, 'budgets', [tBudget])
          .having((s) => s.availableGoals, 'goals', [tGoal]),
    ],
  );

  blocTest<ReportFilterBloc, ReportFilterState>(
    'emits [loading, error] when loading options fails',
    build: () {
      when(
        () => mockGetCategoriesUseCase(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      // Others succeed

      return ReportFilterBloc(
        categoryRepository: mockGetCategoriesUseCase,
        accountRepository: mockGetAssetAccountsUseCase,
        budgetRepository: mockGetBudgetsUseCase,
        goalRepository: mockGetGoalsUseCase,
      );
    },
    expect: () => [
      isA<ReportFilterState>().having(
        (s) => s.optionsStatus,
        'status',
        FilterOptionsStatus.loading,
      ),
      isA<ReportFilterState>()
          .having((s) => s.optionsStatus, 'status', FilterOptionsStatus.error)
          .having(
            (s) => s.optionsError,
            'error',
            contains('Failed to load categories'),
          ),
    ],
  );

  group('UpdateReportFilters', () {
    blocTest<ReportFilterBloc, ReportFilterState>(
      'updates filters correctly',
      build: () => ReportFilterBloc(
        categoryRepository: mockGetCategoriesUseCase,
        accountRepository: mockGetAssetAccountsUseCase,
        budgetRepository: mockGetBudgetsUseCase,
        goalRepository: mockGetGoalsUseCase,
      ),
      act: (bloc) => bloc.add(
        const UpdateReportFilters(
          startDate: null,
          endDate: null,
          categoryIds: ['1'],
          accountIds: ['2'],
          budgetIds: ['3'],
          goalIds: ['4'],
        ),
      ),
      skip: 2, // Skip initial loading/loaded
      expect: () {
        final now = DateTime.now();
        final defaultStart = DateTime(now.year, now.month, 1);
        final defaultEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        return [
          isA<ReportFilterState>()
              .having((s) => s.selectedCategoryIds, 'categories', ['1'])
              .having((s) => s.selectedAccountIds, 'accounts', ['2'])
              .having((s) => s.selectedBudgetIds, 'budgets', ['3'])
              .having((s) => s.selectedGoalIds, 'goals', ['4'])
              // Since we passed null startDate/endDate, it should reset to defaults because the event logic sets clearDates=true if both are null
              // Wait, logic: clearDates: event.startDate == null && event.endDate == null
              // If clearDates is true, copyWith sets startDate to defaultStart.
              .having((s) => s.startDate, 'startDate', defaultStart)
              .having((s) => s.endDate, 'endDate', defaultEnd),
        ];
      },
    );
  });
}
