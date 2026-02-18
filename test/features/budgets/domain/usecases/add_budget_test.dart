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
  });

  final tBudget = Budget(
    id: '1',
    name: 'Test Budget',
    targetAmount: 100.0,
    period: BudgetPeriodType.oneTime,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 1)),
    categoryIds: const [],
    type: BudgetType.overall,
    createdAt: DateTime.now(),
  );

  test('should add budget to repository', () async {
    // Arrange
    when(() => mockUuid.v4()).thenReturn('1');
    when(
      () => mockRepository.addBudget(any()),
    ).thenAnswer((_) async => Right(tBudget));

    // Act
    final result = await useCase(
      AddBudgetParams(
        name: tBudget.name,
        type: tBudget.type,
        targetAmount: tBudget.targetAmount,
        period: tBudget.period,
        startDate: tBudget.startDate,
        endDate: tBudget.endDate,
      ),
    );

    // Assert
    expect(result.isRight(), isTrue);
    verify(() => mockRepository.addBudget(any())).called(1);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(() => mockUuid.v4()).thenReturn('1');
    when(
      () => mockRepository.addBudget(any()),
    ).thenAnswer((_) async => const Left(CacheFailure("Fail")));

    // Act
    final result = await useCase(
      AddBudgetParams(
        name: tBudget.name,
        type: tBudget.type,
        targetAmount: tBudget.targetAmount,
        period: tBudget.period,
        startDate: tBudget.startDate,
        endDate: tBudget.endDate,
      ),
    );

    // Assert
    expect(result, const Left(CacheFailure("Fail")));
  });
}
