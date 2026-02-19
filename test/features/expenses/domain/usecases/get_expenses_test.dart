import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late GetExpensesUseCase usecase;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    usecase = GetExpensesUseCase(mockExpenseRepository);
  });

  final tDate = DateTime(2022, 1, 1);
  final tExpenseModel = ExpenseModel(
    id: '1',
    amount: 100,
    date: tDate,
    categoryId: 'cat1',
    accountId: 'acc1',
    title: 'Test Expense',
  );

  test('should get expenses from the repository', () async {
    // Arrange
    when(
      () => mockExpenseRepository.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => Right([tExpenseModel]));

    // Act
    final result = await usecase(
      GetExpensesParams(
        startDate: tDate,
        endDate: tDate,
        categoryId: 'cat1',
        accountId: 'acc1',
      ),
    );

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Should be Right'),
      (r) => expect(r, [tExpenseModel]),
    );
    verify(
      () => mockExpenseRepository.getExpenses(
        startDate: tDate,
        endDate: tDate,
        categoryId: 'cat1',
        accountId: 'acc1',
      ),
    );
    verifyNoMoreInteractions(mockExpenseRepository);
  });
}
