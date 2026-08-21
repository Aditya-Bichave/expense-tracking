import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late MockExpenseRepository mockExpenseRepo;
  late MockIncomeRepository mockIncomeRepo;
  late TrashBinBloc bloc;

  setUp(() {
    mockExpenseRepo = MockExpenseRepository();
    mockIncomeRepo = MockIncomeRepository();
    bloc = TrashBinBloc(
      expenseRepository: mockExpenseRepo,
      incomeRepository: mockIncomeRepo,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('emits TrashBinError when listDeletedExpenses fails', () async {
    when(
      () => mockExpenseRepo.listDeletedExpenses(),
    ).thenAnswer((_) async => const Left(CacheFailure('Expense fetch error')));
    when(
      () => mockIncomeRepo.listDeletedIncomes(),
    ).thenAnswer((_) async => const Right([]));

    expectLater(
      bloc.stream,
      emitsInOrder([
        TrashBinLoading(),
        const TrashBinError('Expense fetch error'),
      ]),
    );

    bloc.add(LoadTrash());
  });

  test('emits TrashBinError when listDeletedIncomes fails', () async {
    when(
      () => mockExpenseRepo.listDeletedExpenses(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockIncomeRepo.listDeletedIncomes(),
    ).thenAnswer((_) async => const Left(CacheFailure('Income fetch error')));

    expectLater(
      bloc.stream,
      emitsInOrder([
        TrashBinLoading(),
        const TrashBinError('Income fetch error'),
      ]),
    );

    bloc.add(LoadTrash());
  });

  test('emits TrashBinError when restore fails', () async {
    when(
      () => mockExpenseRepo.restoreExpense('exp1'),
    ).thenAnswer((_) async => const Left(CacheFailure('Restore error')));

    expectLater(
      bloc.stream,
      emitsInOrder([const TrashBinError('Restore error')]),
    );

    bloc.add(const RestoreItem(id: 'exp1', type: TrashItemType.expense));
  });

  test('emits TrashBinError when purge fails', () async {
    when(
      () => mockIncomeRepo.purgeIncome('inc1'),
    ).thenAnswer((_) async => const Left(CacheFailure('Purge error')));

    expectLater(
      bloc.stream,
      emitsInOrder([const TrashBinError('Purge error')]),
    );

    bloc.add(const PurgeItem(id: 'inc1', type: TrashItemType.income));
  });
}
