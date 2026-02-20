<<<<<<< HEAD
import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
=======
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
>>>>>>> 1d52882 (feat: Implement Batch 2 tickets (Group Features & Sync))
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
<<<<<<< HEAD
  late MockGroupExpensesRepository mockRepository;

  final tExpense = GroupExpense(
    id: '1',
    groupId: 'g1',
    createdBy: 'c1',
    title: 'Dinner',
    amount: 100,
    currency: 'USD',
    occurredAt: DateTime(2023, 10, 27),
    createdAt: DateTime(2023, 10, 27),
    updatedAt: DateTime(2023, 10, 27),
  );
=======
  late MockGroupExpensesRepository repository;
>>>>>>> 1d52882 (feat: Implement Batch 2 tickets (Group Features & Sync))

  setUpAll(() {
    registerFallbackValue(FakeGroupExpense());
  });

  setUp(() {
<<<<<<< HEAD
    mockRepository = MockGroupExpensesRepository();
    bloc = GroupExpensesBloc(mockRepository);
  });

  group('GroupExpensesBloc', () {
    test('initial state is GroupExpensesInitial', () {
      expect(bloc.state, GroupExpensesInitial());
    });

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [Loading, Loaded] when LoadGroupExpenses is added',
      setUp: () {
        when(
          () => mockRepository.getExpenses(any()),
        ).thenAnswer((_) async => Right([tExpense]));
        when(
          () => mockRepository.syncExpenses(any()),
        ).thenAnswer((_) => Completer<Either<Failure, void>>().future);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroupExpenses('g1')),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
      ],
      verify: (_) {
        verify(() => mockRepository.getExpenses('g1')).called(1);
        verify(() => mockRepository.syncExpenses('g1')).called(1);
      },
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [Loading, Error] when LoadGroupExpenses fails',
      setUp: () {
        when(
          () => mockRepository.getExpenses(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Error')));
        when(
          () => mockRepository.syncExpenses(any()),
        ).thenAnswer((_) => Completer<Either<Failure, void>>().future);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroupExpenses('g1')),
      expect: () => [GroupExpensesLoading(), GroupExpensesError('Error')],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesError] when AddGroupExpenseRequested fails',
      setUp: () {
        when(
          () => mockRepository.addExpense(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Error')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [GroupExpensesError('Error')],
=======
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
>>>>>>> 1d52882 (feat: Implement Batch 2 tickets (Group Features & Sync))
    );
  });
}
