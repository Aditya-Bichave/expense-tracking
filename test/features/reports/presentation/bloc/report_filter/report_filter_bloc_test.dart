import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
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

    // Default success responses
    when(() => mockGetCategoriesUseCase(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => mockGetAssetAccountsUseCase(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => mockGetBudgetsUseCase(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => mockGetGoalsUseCase(any()))
        .thenAnswer((_) async => const Right([]));
  });

  group('LoadFilterOptions', () {
    blocTest<ReportFilterBloc, ReportFilterState>(
      'emits [loaded] with empty lists on success',
      build: () => ReportFilterBloc(
        categoryRepository: mockGetCategoriesUseCase,
        accountRepository: mockGetAssetAccountsUseCase,
        budgetRepository: mockGetBudgetsUseCase,
        goalRepository: mockGetGoalsUseCase,
      ),
      // Initial load triggered in constructor
      expect: () => [
        isA<ReportFilterState>().having(
            (s) => s.optionsStatus, 'status', FilterOptionsStatus.loading),
        isA<ReportFilterState>()
            .having(
                (s) => s.optionsStatus, 'status', FilterOptionsStatus.loaded)
            .having((s) => s.availableCategories, 'cats', isEmpty),
      ],
    );

    blocTest<ReportFilterBloc, ReportFilterState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => mockGetCategoriesUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure('Error')));
        return ReportFilterBloc(
          categoryRepository: mockGetCategoriesUseCase,
          accountRepository: mockGetAssetAccountsUseCase,
          budgetRepository: mockGetBudgetsUseCase,
          goalRepository: mockGetGoalsUseCase,
        );
      },
      expect: () => [
        isA<ReportFilterState>().having(
            (s) => s.optionsStatus, 'status', FilterOptionsStatus.loading),
        isA<ReportFilterState>()
            .having((s) => s.optionsStatus, 'status', FilterOptionsStatus.error)
            .having((s) => s.optionsError, 'error', contains('Failed to load')),
      ],
    );
  });

  group('UpdateReportFilters', () {
    blocTest<ReportFilterBloc, ReportFilterState>(
      'emits updated state',
      build: () => ReportFilterBloc(
        categoryRepository: mockGetCategoriesUseCase,
        accountRepository: mockGetAssetAccountsUseCase,
        budgetRepository: mockGetBudgetsUseCase,
        goalRepository: mockGetGoalsUseCase,
      ),
      skip: 2, // Skip initial load states
      act: (bloc) => bloc.add(UpdateReportFilters(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 31),
        categoryIds: const ['c1'],
        accountIds: const ['a1'],
      )),
      expect: () => [
        isA<ReportFilterState>()
            .having((s) => s.startDate, 'startDate', DateTime(2023, 1, 1))
            .having((s) => s.selectedCategoryIds, 'cats', ['c1']),
      ],
    );
  });

  group('ClearReportFilters', () {
    blocTest<ReportFilterBloc, ReportFilterState>(
      'resets filters to defaults',
      build: () => ReportFilterBloc(
        categoryRepository: mockGetCategoriesUseCase,
        accountRepository: mockGetAssetAccountsUseCase,
        budgetRepository: mockGetBudgetsUseCase,
        goalRepository: mockGetGoalsUseCase,
      ),
      seed: () => ReportFilterState.initial().copyWith(
        startDate: DateTime(2023, 1, 1),
        selectedCategoryIds: ['c1'],
      ),
      skip: 2, // Skip initial load
      act: (bloc) => bloc.add(const ClearReportFilters()),
      expect: () => [
        isA<ReportFilterState>()
            .having((s) => s.selectedCategoryIds, 'cats', isEmpty)
            .having((s) => s.startDate.year, 'startYear', DateTime.now().year),
      ],
    );
  });
}
