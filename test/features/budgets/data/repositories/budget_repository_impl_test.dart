import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late BudgetRepositoryImpl repository;
  late MockBudgetLocalDataSource mockLocalDataSource;
  late MockExpenseRepository mockExpenseRepository;

  setUpAll(() {
    registerFallbackValue(
      BudgetModel(
        id: '',
        name: '',
        budgetTypeIndex: BudgetType.overall.index,
        targetAmount: 0,
        periodTypeIndex: BudgetPeriodType.recurringMonthly.index,
        createdAt: DateTime(2000),
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockBudgetLocalDataSource();
    mockExpenseRepository = MockExpenseRepository();
    repository = BudgetRepositoryImpl(
      localDataSource: mockLocalDataSource,
      expenseRepository: mockExpenseRepository,
    );
  });

  test('allows one-time budgets to coexist with recurring budgets', () async {
    final existingRecurring = Budget(
      id: 'r1',
      name: 'Recurring',
      type: BudgetType.categorySpecific,
      targetAmount: 100,
      period: BudgetPeriodType.recurringMonthly,
      categoryIds: ['c1'],
      startDate: null,
      endDate: null,
      notes: null,
      createdAt: DateTime(2023, 1, 1),
    );

    when(
      () => mockLocalDataSource.getBudgets(),
    ).thenAnswer((_) async => [BudgetModel.fromEntity(existingRecurring)]);
    when(
      () => mockLocalDataSource.saveBudget(any()),
    ).thenAnswer((_) async => {});

    final oneTime = Budget(
      id: 'o1',
      name: 'One Time',
      type: BudgetType.categorySpecific,
      targetAmount: 50,
      period: BudgetPeriodType.oneTime,
      startDate: DateTime(2023, 12, 1),
      endDate: DateTime(2023, 12, 31),
      categoryIds: ['c1'],
      notes: null,
      createdAt: DateTime(2023, 6, 1),
    );

    final result = await repository.addBudget(oneTime);

    expect(result.isRight(), true);
    verify(() => mockLocalDataSource.saveBudget(any())).called(1);
  });
}
