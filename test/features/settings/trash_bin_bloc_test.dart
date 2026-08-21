import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late TrashBinBloc bloc;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    bloc = TrashBinBloc(
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tDeletedDate = DateTime(2026, 4, 1);
  final tDeletedExpense = ExpenseModel(
    id: 'exp1',
    title: 'Deleted Coffee',
    amount: 5.0,
    date: DateTime(2026, 3, 30),
    accountId: 'acc1',
    deletedAt: tDeletedDate,
  );
  final tDeletedIncome = IncomeModel(
    id: 'inc1',
    title: 'Deleted Bonus',
    amount: 100.0,
    date: DateTime(2026, 3, 29),
    accountId: 'acc1',
    deletedAt: tDeletedDate,
  );

  group('TrashBinBloc', () {
    test('initial state is TrashBinInitial', () {
      expect(bloc.state, isA<TrashBinInitial>());
    });

    test(
      'LoadTrash emits [TrashBinLoading, TrashBinLoaded] when deleted items exist',
      () async {
        when(
          () => mockExpenseRepository.listDeletedExpenses(),
        ).thenAnswer((_) async => Right([tDeletedExpense]));
        when(
          () => mockIncomeRepository.listDeletedIncomes(),
        ).thenAnswer((_) async => Right([tDeletedIncome]));

        final expectedStates = [
          isA<TrashBinLoading>(),
          isA<TrashBinLoaded>().having((s) => s.items.length, 'length', 2),
        ];

        expectLater(bloc.stream, emitsInOrder(expectedStates));

        bloc.add(LoadTrash());
      },
    );

    test(
      'LoadTrash emits [TrashBinLoading, TrashBinEmpty] when no deleted items exist',
      () async {
        when(
          () => mockExpenseRepository.listDeletedExpenses(),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => mockIncomeRepository.listDeletedIncomes(),
        ).thenAnswer((_) async => const Right([]));

        final expectedStates = [isA<TrashBinLoading>(), isA<TrashBinEmpty>()];

        expectLater(bloc.stream, emitsInOrder(expectedStates));

        bloc.add(LoadTrash());
      },
    );

    test('RestoreItem calls restoreExpense and triggers LoadTrash', () async {
      when(
        () => mockExpenseRepository.restoreExpense('exp1'),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockExpenseRepository.listDeletedExpenses(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockIncomeRepository.listDeletedIncomes(),
      ).thenAnswer((_) async => const Right([]));

      bloc.add(const RestoreItem(id: 'exp1', type: TrashItemType.expense));

      await untilCalled(() => mockExpenseRepository.restoreExpense('exp1'));
      verify(() => mockExpenseRepository.restoreExpense('exp1')).called(1);
    });

    test('PurgeItem calls purgeExpense and triggers LoadTrash', () async {
      when(
        () => mockExpenseRepository.purgeExpense('exp1'),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockExpenseRepository.listDeletedExpenses(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockIncomeRepository.listDeletedIncomes(),
      ).thenAnswer((_) async => const Right([]));

      bloc.add(const PurgeItem(id: 'exp1', type: TrashItemType.expense));

      await untilCalled(() => mockExpenseRepository.purgeExpense('exp1'));
      verify(() => mockExpenseRepository.purgeExpense('exp1')).called(1);
    });
  });
}
