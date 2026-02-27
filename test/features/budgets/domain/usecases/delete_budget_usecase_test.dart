import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late DeleteBudgetUseCase useCase;
  late MockBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = DeleteBudgetUseCase(mockRepository);
  });

  test('should call repository.deleteBudget', () async {
    when(
      () => mockRepository.deleteBudget('1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(const DeleteBudgetParams(id: '1'));

    expect(result, const Right(null));
    verify(() => mockRepository.deleteBudget('1')).called(1);
  });
}
