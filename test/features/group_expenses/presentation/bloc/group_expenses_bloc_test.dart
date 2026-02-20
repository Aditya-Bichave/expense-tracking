import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupExpensesRepository extends Mock implements GroupExpensesRepository {}

class FakeGroupExpense extends Fake implements GroupExpense {}

void main() {
  late GroupExpensesBloc bloc;
  late MockGroupExpensesRepository mockRepository;

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

  final tGroupId = 'group1';
  final tDate = DateTime.now();
  final tExpense = GroupExpense(
    id: '1',
    groupId: tGroupId,
    createdBy: 'user1',
    title: 'Dinner',
    amount: 100.0,
    currency: 'USD',
    occurredAt: tDate,
    createdAt: tDate,
    updatedAt: tDate,
    payers: const [],
    splits: const [],
  );

  group('GroupExpensesBloc', () {
    test('initial state is GroupExpensesInitial', () {
      expect(bloc.state, GroupExpensesInitial());
    });

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesLoading, GroupExpensesLoaded, GroupExpensesLoaded] when LoadGroupExpenses succeeds',
      build: () {
        when(() => mockRepository.getExpenses(tGroupId))
            .thenAnswer((_) async => Right([tExpense]));
        when(() => mockRepository.syncExpenses(tGroupId))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadGroupExpenses(tGroupId)),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
        // Second loaded emitted after sync and fetch
        GroupExpensesLoaded([tExpense]),
      ],
      verify: (_) {
        verify(() => mockRepository.getExpenses(tGroupId)).called(2);
        verify(() => mockRepository.syncExpenses(tGroupId)).called(1);
      },
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesLoading, GroupExpensesError] when LoadGroupExpenses fails',
      build: () {
        when(() => mockRepository.getExpenses(tGroupId))
            .thenAnswer((_) async => Left(ServerFailure('Error')));
        when(() => mockRepository.syncExpenses(tGroupId))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadGroupExpenses(tGroupId)),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesError('Error'),
        // Duplicate error states are skipped by Equatable
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesLoading] (via LoadGroupExpenses) when AddGroupExpenseRequested succeeds',
      build: () {
        when(() => mockRepository.addExpense(any()))
            .thenAnswer((_) async => Right(tExpense));
        when(() => mockRepository.getExpenses(tGroupId))
            .thenAnswer((_) async => Right([tExpense]));
        when(() => mockRepository.syncExpenses(tGroupId))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        GroupExpensesLoading(),
        GroupExpensesLoaded([tExpense]),
        // Second loaded emitted after sync and fetch
        GroupExpensesLoaded([tExpense]),
      ],
    );

    blocTest<GroupExpensesBloc, GroupExpensesState>(
      'emits [GroupExpensesError] when AddGroupExpenseRequested fails',
      build: () {
        when(() => mockRepository.addExpense(any()))
            .thenAnswer((_) async => Left(ServerFailure('Add Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(AddGroupExpenseRequested(tExpense)),
      expect: () => [
        GroupExpensesError('Add Error'),
      ],
    );
  });
}
