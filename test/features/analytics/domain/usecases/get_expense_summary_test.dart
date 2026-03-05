import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockExpenseSummary extends Mock implements ExpenseSummary {
  @override
  double get totalExpenses => 1000.0;

  @override
  Map<String, double> get categoryBreakdown => {'Food': 1000.0};
}

void main() {
  late MockExpenseRepository mockRepository;
  late GetExpenseSummaryUseCase usecase;
  late MockExpenseSummary tSummary;

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = GetExpenseSummaryUseCase(mockRepository);
    tSummary = MockExpenseSummary();
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  test('should get expense summary from repository', () async {
    when(
      () => mockRepository.getExpenseSummary(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => Right(tSummary));

    final result = await usecase(tParams);

    expect(result, Right(tSummary));
    verify(
      () => mockRepository.getExpenseSummary(
        startDate: tStartDate,
        endDate: tEndDate,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(
      () => mockRepository.getExpenseSummary(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('error')));

    final result = await usecase(tParams);

    expect(result, const Left(CacheFailure('error')));
    verify(
      () => mockRepository.getExpenseSummary(
        startDate: tStartDate,
        endDate: tEndDate,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('GetSummaryParams equality', () {
    final params1 = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);
    final params2 = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);
    final params3 = GetSummaryParams(
      startDate: tStartDate,
      endDate: DateTime(2023, 2, 1),
    );

    expect(params1, equals(params2));
    expect(params1, isNot(equals(params3)));
  });
}
