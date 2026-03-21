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

  final tUpdatedExpense = GroupExpense(
    id: '1',
    groupId: 'g1',
    createdBy: 'c1',
    title: 'Dinner Updated',
    amount: 150,
    currency: 'USD',
    occurredAt: DateTime(2023, 10, 27),
    createdAt: DateTime(2023, 10, 27),
    updatedAt: DateTime(2023, 10, 28),
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
      act: (bloc) => bloc.add(const LoadGroupExpenses('g1')),
      expect: () => [
        const GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [Loading, Error] when LoadGroupExpenses fails',
      setUp: () {
        when(
          () => mockRepository.getExpenses('g1'),
        ).thenAnswer((_) async => const Left(CacheFailure('Error')));
        when(
          () => mockRepository.syncExpenses('g1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadGroupExpenses('g1')),
      expect: () => [
        const GroupExpensesLoading(),
        const GroupExpensesError('Error'),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits syncError when AddGroupExpenseRequested fails',
      setUp: () {
        when(
          () => mockRepository.addExpense(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Error')));
      },
      build: () => bloc,
      seed: () => const GroupExpensesLoaded([]),
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        const GroupExpensesLoading(),
        const GroupExpensesOperationFailed('Error', []),
        const GroupExpensesLoaded([]),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'reloads expenses after a successful add',
      setUp: () {
        when(
          () => mockRepository.addExpense(any()),
        ).thenAnswer((_) async => Right(tExpense));
      },
      build: () => bloc,
      seed: () => const GroupExpensesLoaded([]),
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        const GroupExpensesLoading(),
        GroupExpenseOperationSucceeded(tExpense),
        GroupExpensesLoaded([tExpense]),
      ],
      verify: (_) {
        verify(() => mockRepository.addExpense(tExpense)).called(1);
      },
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits syncError when UpdateGroupExpenseRequested fails',
      setUp: () {
        when(
          () => mockRepository.updateExpense(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Error')));
      },
      build: () => bloc,
      seed: () => GroupExpensesLoaded([tExpense]),
      act: (bloc) => bloc.add(UpdateGroupExpenseRequested(tUpdatedExpense)),
      expect: () => [
        const GroupExpensesLoading(),
        GroupExpensesOperationFailed('Error', [tExpense]),
        GroupExpensesLoaded([tExpense]),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'updates expenses after a successful edit',
      setUp: () {
        when(
          () => mockRepository.updateExpense(any()),
        ).thenAnswer((_) async => Right(tUpdatedExpense));
      },
      build: () => bloc,
      seed: () => GroupExpensesLoaded([tExpense]),
      act: (bloc) => bloc.add(UpdateGroupExpenseRequested(tUpdatedExpense)),
      expect: () => [
        const GroupExpensesLoading(),
        GroupExpenseOperationSucceeded(tUpdatedExpense),
        GroupExpensesLoaded([tUpdatedExpense]),
      ],
      verify: (_) {
        verify(() => mockRepository.updateExpense(tUpdatedExpense)).called(1);
      },
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits syncError when DeleteGroupExpenseRequested fails',
      setUp: () {
        when(
          () => mockRepository.deleteExpense(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Error')));
      },
      build: () => bloc,
      seed: () => GroupExpensesLoaded([tExpense]),
      act: (bloc) => bloc.add(const DeleteGroupExpenseRequested('1')),
      expect: () => [
        const GroupExpensesLoading(),
        GroupExpensesOperationFailed('Error', [tExpense]),
        GroupExpensesLoaded([tExpense]),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'removes expense after a successful delete',
      setUp: () {
        when(
          () => mockRepository.deleteExpense(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      seed: () => GroupExpensesLoaded([tExpense]),
      act: (bloc) => bloc.add(const DeleteGroupExpenseRequested('1')),
      expect: () => [
        const GroupExpensesLoading(),
        const GroupExpenseOperationSucceeded(null),
        const GroupExpensesLoaded([]),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteExpense('1')).called(1);
      },
    );
  });
}
