import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late AddBudgetUseCase useCase;
  late MockBudgetRepository mockRepository;
  late MockUuid mockUuid;

  setUp(() {
    mockRepository = MockBudgetRepository();
    mockUuid = MockUuid();
    useCase = AddBudgetUseCase(mockRepository, mockUuid);
    registerFallbackValue(
      Budget(
        id: '1',
        name: 'test',
        targetAmount: 100,
        type: BudgetType.overall,
        period: BudgetPeriodType.oneTime,
        createdAt: DateTime.now(),
      ),
    );
  });

  const tBudgetParams = AddBudgetParams(
    name: 'Food',
    targetAmount: 500,
    type: BudgetType.categorySpecific,
    period: BudgetPeriodType.recurringMonthly,
    categoryIds: ['cat1'],
  );

  test('should add budget successfully', () async {
    when(() => mockUuid.v4()).thenReturn('1');
    when(() => mockRepository.addBudget(any())).thenAnswer((invocation) async {
      return Right(invocation.positionalArguments[0] as Budget);
    });

    final result = await useCase(tBudgetParams);

    expect(result.isRight(), true);
    verify(() => mockRepository.addBudget(any())).called(1);
  });

  test('should return failure when validation fails (empty name)', () async {
    final result = await useCase(
      const AddBudgetParams(
        name: '',
        targetAmount: 500,
        type: BudgetType.overall,
        period: BudgetPeriodType.recurringMonthly,
      ),
    );
    expect(result.isLeft(), true);
    result.fold((l) => expect(l, isA<ValidationFailure>()), (r) => null);
  });

  test('should return failure when target amount is negative', () async {
    final result = await useCase(
      const AddBudgetParams(
        name: 'Test',
        targetAmount: -100,
        type: BudgetType.overall,
        period: BudgetPeriodType.recurringMonthly,
      ),
    );
    expect(result.isLeft(), true);
  });

  test(
    'should return failure when category specific budget has no categories',
    () async {
      final result = await useCase(
        const AddBudgetParams(
          name: 'Test',
          targetAmount: 100,
          type: BudgetType.categorySpecific,
          period: BudgetPeriodType.recurringMonthly,
          categoryIds: [],
        ),
      );
      expect(result.isLeft(), true);
    },
  );

  test('should return failure when one-time budget has no dates', () async {
    final result = await useCase(
      const AddBudgetParams(
        name: 'Test',
        targetAmount: 100,
        type: BudgetType.overall,
        period: BudgetPeriodType.oneTime,
      ),
    );
    expect(result.isLeft(), true);
  });

  test('should return failure when end date is before start date', () async {
    final result = await useCase(
      AddBudgetParams(
        name: 'Test',
        targetAmount: 100,
        type: BudgetType.overall,
        period: BudgetPeriodType.oneTime,
        startDate: DateTime.now(),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    expect(result.isLeft(), true);
  });
}
