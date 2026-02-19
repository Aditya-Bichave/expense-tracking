import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late GetIncomesUseCase usecase;
  late MockIncomeRepository mockIncomeRepository;

  setUp(() {
    mockIncomeRepository = MockIncomeRepository();
    usecase = GetIncomesUseCase(mockIncomeRepository);
  });

  final tDate = DateTime(2022, 1, 1);
  final tIncomeModel = IncomeModel(
    id: '1',
    amount: 100,
    date: tDate,
    categoryId: 'cat1',
    accountId: 'acc1',
    title: 'Test Income',
  );

  test('should get incomes from the repository', () async {
    // Arrange
    when(
      () => mockIncomeRepository.getIncomes(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => Right([tIncomeModel]));

    // Act
    final result = await usecase(
      GetIncomesParams(
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
      (r) => expect(r, [tIncomeModel]),
    );
    verify(
      () => mockIncomeRepository.getIncomes(
        startDate: tDate,
        endDate: tDate,
        categoryId: 'cat1',
        accountId: 'acc1',
      ),
    );
    verifyNoMoreInteractions(mockIncomeRepository);
  });
}
