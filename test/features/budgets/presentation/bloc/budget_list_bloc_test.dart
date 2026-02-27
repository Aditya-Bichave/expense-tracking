import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetsUseCase extends Mock implements GetBudgetsUseCase {}

class MockDeleteBudgetUseCase extends Mock implements DeleteBudgetUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockGetBudgetsUseCase mockGetBudgetsUseCase;
  late MockDeleteBudgetUseCase mockDeleteBudgetUseCase;
  late MockExpenseRepository mockExpenseRepository;
  late Stream<DataChangedEvent> dataChangeStream;

  setUp(() {
    mockGetBudgetsUseCase = MockGetBudgetsUseCase();
    mockDeleteBudgetUseCase = MockDeleteBudgetUseCase();
    mockExpenseRepository = MockExpenseRepository();
    dataChangeStream = const Stream.empty();
    registerFallbackValue(NoParams());
    registerFallbackValue(const DeleteBudgetParams(id: '1'));
  });

  final tBudget = Budget(
    id: '1',
    name: 'Food',
    targetAmount: 500,
    type: BudgetType.categorySpecific,
    period: BudgetPeriodType.oneTime,
    categoryIds: ['cat1'],
    startDate: DateTime.now(),
    endDate: DateTime.now(),
    createdAt: DateTime.now(),
  );

  blocTest<BudgetListBloc, BudgetListState>(
    'emits [loading, success] when LoadBudgets is added and succeeds',
    build: () {
      when(() => mockGetBudgetsUseCase(any())).thenAnswer((_) async => Right([tBudget]));
      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Right([]));
      return BudgetListBloc(
        getBudgetsUseCase: mockGetBudgetsUseCase,
        deleteBudgetUseCase: mockDeleteBudgetUseCase,
        expenseRepository: mockExpenseRepository,
        dataChangeStream: dataChangeStream,
      );
    },
    act: (bloc) => bloc.add(const LoadBudgets()),
    expect: () => [
      const BudgetListState(status: BudgetListStatus.loading), // Fixed: Removed clearError
      isA<BudgetListState>()
          .having((s) => s.status, 'status', BudgetListStatus.success)
          .having((s) => s.budgetsWithStatus.length, 'budgets', 1),
    ],
  );

  blocTest<BudgetListBloc, BudgetListState>(
    'calculates status correctly with expenses',
    build: () {
      final startDate = DateTime.now().subtract(const Duration(days: 1));
      final endDate = DateTime.now().add(const Duration(days: 1));
      final budgetWithDates = tBudget.copyWith(
        startDate: startDate,
        endDate: endDate,
      );

      when(
        () => mockGetBudgetsUseCase(any()),
      ).thenAnswer((_) async => Right([budgetWithDates]));

      final expenses = [
        ExpenseModel(
          id: 'e1',
          title: 'Exp1',
          amount: 100,
          date: DateTime.now(),
          categoryId: 'cat1',
          accountId: 'a1',
        ),
      ];

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => Right(expenses));

      return BudgetListBloc(
        getBudgetsUseCase: mockGetBudgetsUseCase,
        deleteBudgetUseCase: mockDeleteBudgetUseCase,
        expenseRepository: mockExpenseRepository,
        dataChangeStream: dataChangeStream,
      );
    },
    act: (bloc) => bloc.add(const LoadBudgets()),
    expect: () => [
      const BudgetListState(status: BudgetListStatus.loading), // Fixed: Removed clearError
      isA<BudgetListState>().having(
        (s) => s.budgetsWithStatus.first.amountSpent,
        'amountSpent',
        100.0,
      ),
    ],
  );
}
