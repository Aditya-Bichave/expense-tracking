import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupExpensesRepository extends Mock
    implements GroupExpensesRepository {}

class FakeGroupExpense extends Fake implements GroupExpense {}

void main() {
  late GroupExpensesBloc bloc;
  late MockGroupExpensesRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeGroupExpense());
  });

  setUp(() {
    repository = MockGroupExpensesRepository();
    bloc = GroupExpensesBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AddGroupExpenseRequested', () {
    final invalidSplitExpense = GroupExpense(
      id: '1',
      groupId: 'g1',
      createdBy: 'u1',
      title: 'Lunch',
      amount: 100,
      currency: 'USD',
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      payers: const [ExpensePayer(userId: 'u1', amount: 100)],
      splits: const [
        ExpenseSplit(userId: 'u1', amount: 40, splitType: SplitType.exact),
        ExpenseSplit(userId: 'u2', amount: 40, splitType: SplitType.exact),
      ], // Sum = 80 != 100
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesError] when splits do not sum to total amount',
      build: () {
        when(
          () => repository.addExpense(any()),
        ).thenAnswer((_) async => Right(invalidSplitExpense));
        when(
          () => repository.getExpenses(any()),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => repository.syncExpenses(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(AddGroupExpenseRequested(invalidSplitExpense)),
      expect: () => [
        GroupExpensesError('Splits must sum to total amount: 100.0'),
      ],
    );

    final invalidPayerExpense = GroupExpense(
      id: '2',
      groupId: 'g1',
      createdBy: 'u1',
      title: 'Dinner',
      amount: 100,
      currency: 'USD',
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      payers: const [
        ExpensePayer(userId: 'u1', amount: 50),
        ExpensePayer(userId: 'u2', amount: 40),
      ], // Sum = 90 != 100
      splits: const [],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesError] when payers do not sum to total amount',
      build: () {
        when(
          () => repository.addExpense(any()),
        ).thenAnswer((_) async => Right(invalidPayerExpense));
        return bloc;
      },
      act: (bloc) => bloc.add(AddGroupExpenseRequested(invalidPayerExpense)),
      expect: () => [
        GroupExpensesError('Payers must sum to total amount: 100.0'),
      ],
    );
  });
}
