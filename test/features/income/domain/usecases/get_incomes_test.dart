import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late GetIncomesUseCase useCase;
  late MockIncomeRepository mockRepository;

  setUp(() {
    mockRepository = MockIncomeRepository();
    useCase = GetIncomesUseCase(mockRepository);
  });

  final tDate = DateTime.fromMillisecondsSinceEpoch(0);
  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 1.0,
    isRecurring: true,
  );

  final tIncomeEntity = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    category: null, // toEntity produces null category
    notes: null,
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
    isRecurring: true,
  );

  const tParams = GetIncomesParams(
    startDate: null,
    endDate: null,
    category: null,
    accountId: null,
  );

  test('should return list of incomes from repository', () async {
    // Arrange
    when(() => mockRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        )).thenAnswer((_) async => Right([tIncomeModel]));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Expected Right, got Left $l'),
      (r) => expect(r, [tIncomeEntity]),
    );
    verify(() => mockRepository.getIncomes(
          startDate: null,
          endDate: null,
          categoryId: null,
          accountId: null,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should propagate Failure from repository', () async {
    // Arrange
    when(() => mockRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        )).thenAnswer((_) async => const Left(CacheFailure("Error")));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Left(CacheFailure("Error")));
    verify(() => mockRepository.getIncomes(
          startDate: null,
          endDate: null,
          categoryId: null,
          accountId: null,
        )).called(1);
  });
}
