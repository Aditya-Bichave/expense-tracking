import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_event.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_state.dart';
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
    payers: const [],
    splits: const [],
  );

  setUpAll(() {
    registerFallbackValue(FakeGroupExpense());
  });

  setUp(() {
    mockRepository = MockGroupExpensesRepository();
    bloc = GroupExpensesBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('GroupExpensesBloc initial state is GroupExpensesInitial', () {
    expect(bloc.state, const GroupExpensesInitial());
  });

  group('GroupExpensesBloc', () {
    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [Loading, Loaded] when LoadGroupExpenses is added',
      setUp: () {
        when(
          () => mockRepository.getExpenses('g1'),
        ).thenAnswer((_) async => Right([tExpense]));
        when(
          () => mockRepository.syncExpenses('g1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroupExpenses('g1')),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [Loading, Error] when LoadGroupExpenses fails',
      setUp: () {
        when(
          () => mockRepository.getExpenses('g1'),
        ).thenAnswer((_) async => Left(CacheFailure('Error')));
        when(
          () => mockRepository.syncExpenses('g1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroupExpenses('g1')),
      expect: () => [GroupExpensesLoading(), GroupExpensesError('Error')],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits syncError when AddGroupExpenseRequested fails',
      setUp: () {
        when(
          () => mockRepository.addExpense(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Error')));
      },
      build: () => bloc,
      seed: () => GroupExpensesLoaded(const []),
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded(const [], syncError: 'Error')
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
      seed: () => GroupExpensesLoaded(const []),
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
      ],
      verify: (_) {
        verify(() => mockRepository.addExpense(tExpense)).called(1);
      },
    );
  });
}
