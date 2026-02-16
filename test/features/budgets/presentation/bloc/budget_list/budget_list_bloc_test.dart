import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetsUseCase extends Mock implements GetBudgetsUseCase {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockDeleteBudgetUseCase extends Mock implements DeleteBudgetUseCase {}

void main() {
  late BudgetListBloc bloc;
  late MockGetBudgetsUseCase mockGetBudgetsUseCase;
  late MockBudgetRepository mockBudgetRepository;
  late MockDeleteBudgetUseCase mockDeleteBudgetUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  final tBudget = Budget(
    id: '1',
    name: 'Test Budget',
    targetAmount: 500,
    type: BudgetType.categorySpecific,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const DeleteBudgetParams(id: ''));
    registerFallbackValue(tBudget);
  });

  setUp(() {
    mockGetBudgetsUseCase = MockGetBudgetsUseCase();
    mockBudgetRepository = MockBudgetRepository();
    mockDeleteBudgetUseCase = MockDeleteBudgetUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = BudgetListBloc(
      getBudgetsUseCase: mockGetBudgetsUseCase,
      budgetRepository: mockBudgetRepository,
      deleteBudgetUseCase: mockDeleteBudgetUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  group('LoadBudgets', () {
    blocTest<BudgetListBloc, BudgetListState>(
      'emits [loading, success] with calculated status when successful',
      build: () {
        when(
          () => mockGetBudgetsUseCase(any()),
        ).thenAnswer((_) async => Right([tBudget]));
        when(
          () => mockBudgetRepository.calculateAmountSpent(
            budget: any(named: 'budget'),
            periodStart: any(named: 'periodStart'),
            periodEnd: any(named: 'periodEnd'),
          ),
        ).thenAnswer((_) async => const Right(100.0));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        const BudgetListState(status: BudgetListStatus.loading),
        isA<BudgetListState>()
            .having((s) => s.status, 'status', BudgetListStatus.success)
            .having((s) => s.budgetsWithStatus.length, 'budgetsCount', 1)
            .having((s) => s.budgetsWithStatus.first.amountSpent, 'spent', 100),
      ],
    );

    blocTest<BudgetListBloc, BudgetListState>(
      'emits [loading, error] when fetch fails',
      build: () {
        when(
          () => mockGetBudgetsUseCase(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        const BudgetListState(status: BudgetListStatus.loading),
        isA<BudgetListState>().having(
          (s) => s.status,
          'status',
          BudgetListStatus.error,
        ),
      ],
    );
  });

  group('DeleteBudget', () {
    blocTest<BudgetListBloc, BudgetListState>(
      'emits optimistic update and then success',
      seed: () => BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [
          BudgetWithStatus(
            budget: tBudget,
            amountSpent: 0,
            amountRemaining: 500,
            percentageUsed: 0,
            health: BudgetHealth.thriving,
            statusColor: const Color(0x00000000),
          ),
        ],
      ),
      build: () {
        when(
          () => mockDeleteBudgetUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteBudget(budgetId: tBudget.id)),
      expect: () => [
        isA<BudgetListState>().having(
          (s) => s.budgetsWithStatus,
          'budgets',
          isEmpty,
        ),
      ],
      verify: (_) {
        verify(
          () => mockDeleteBudgetUseCase(DeleteBudgetParams(id: tBudget.id)),
        ).called(1);
      },
    );
  });

  group('DataChangedEvent', () {
    blocTest<BudgetListBloc, BudgetListState>(
      'triggers reload on budget change',
      build: () {
        when(
          () => mockGetBudgetsUseCase(any()),
        ).thenAnswer((_) async => Right([tBudget]));
        when(
          () => mockBudgetRepository.calculateAmountSpent(
            budget: any(named: 'budget'),
            periodStart: any(named: 'periodStart'),
            periodEnd: any(named: 'periodEnd'),
          ),
        ).thenAnswer((_) async => const Right(100.0));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(
          const DataChangedEvent(
            type: DataChangeType.budget,
            reason: DataChangeReason.updated,
          ),
        );
      },
      expect: () => [
        const BudgetListState(status: BudgetListStatus.loading),
        isA<BudgetListState>().having(
          (s) => s.status,
          'status',
          BudgetListStatus.success,
        ),
      ],
    );
  });
}
