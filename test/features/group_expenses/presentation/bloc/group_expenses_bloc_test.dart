import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
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

  setUpAll(() {
    registerFallbackValue(FakeGroupExpense());
  });

  setUp(() {
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
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits refreshed expenses after sync changes local data',
      setUp: () {
        var readCount = 0;
        when(() => mockRepository.getExpenses('g1')).thenAnswer((_) async {
          readCount += 1;
          if (readCount == 1) {
            return Right([tExpense]);
          }
          return Right([
            GroupExpense(
              id: tExpense.id,
              groupId: tExpense.groupId,
              createdBy: tExpense.createdBy,
              title: 'Dinner Updated',
              amount: tExpense.amount,
              currency: tExpense.currency,
              occurredAt: tExpense.occurredAt,
              createdAt: tExpense.createdAt,
              updatedAt: DateTime(2023, 10, 28),
              payers: tExpense.payers,
              splits: tExpense.splits,
            ),
          ]);
        });
        when(
          () => mockRepository.syncExpenses(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroupExpenses('g1')),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
        isA<GroupExpensesLoaded>().having(
          (state) => state.expenses.single.title,
          'updated title',
          'Dinner Updated',
        ),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'reloads expenses after a successful add',
      setUp: () {
        when(
          () => mockRepository.addExpense(any()),
        ).thenAnswer((_) async => Right(tExpense));
        when(
          () => mockRepository.getExpenses(any()),
        ).thenAnswer((_) async => Right([tExpense]));
        when(
          () => mockRepository.syncExpenses(any()),
        ).thenAnswer((_) => Completer<Either<Failure, void>>().future);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
      ],
      verify: (_) {
        verify(() => mockRepository.addExpense(tExpense)).called(1);
        verify(() => mockRepository.getExpenses('g1')).called(1);
      },
    );
  });
}
