import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetExpenseSummaryUseCase extends Mock
    implements GetExpenseSummaryUseCase {}

class FakeGetSummaryParams extends Fake implements GetSummaryParams {}

void main() {
  late MockGetExpenseSummaryUseCase mockUseCase;
  late StreamController<DataChangedEvent> dataChangeStreamController;
  late SummaryBloc bloc;

  setUpAll(() {
    registerFallbackValue(FakeGetSummaryParams());
  });

  setUp(() {
    mockUseCase = MockGetExpenseSummaryUseCase();
    dataChangeStreamController = StreamController<DataChangedEvent>.broadcast();
    bloc = SummaryBloc(
      getExpenseSummaryUseCase: mockUseCase,
      dataChangeStream: dataChangeStreamController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeStreamController.close();
  });

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );
  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);

  test('initial state is SummaryInitial', () {
    expect(bloc.state, isA<SummaryInitial>());
  });

  blocTest<SummaryBloc, SummaryState>(
    'emits [SummaryLoading, SummaryLoaded] when LoadSummary is added and succeeds',
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => const Right(tExpenseSummary));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadSummary(startDate: tStartDate, endDate: tEndDate)),
    expect: () => [
      const SummaryLoading(isReloading: false),
      const SummaryLoaded(tExpenseSummary),
    ],
    verify: (_) {
      verify(() => mockUseCase(
            GetSummaryParams(startDate: tStartDate, endDate: tEndDate),
          )).called(1);
    },
  );

  blocTest<SummaryBloc, SummaryState>(
    'emits [SummaryLoading, SummaryError] when LoadSummary is added and fails',
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Error')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadSummary()),
    expect: () => [
      const SummaryLoading(isReloading: false),
      const SummaryError('Could not load summary from local data. Error'),
    ],
  );

  blocTest<SummaryBloc, SummaryState>(
    'emits [SummaryLoading, SummaryLoaded] with previous data when reloading',
    seed: () => const SummaryLoaded(tExpenseSummary),
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => const Right(tExpenseSummary));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadSummary(forceReload: true)),
    expect: () => [
      const SummaryLoading(isReloading: true, previousSummary: tExpenseSummary),
      const SummaryLoaded(tExpenseSummary),
    ],
  );

  blocTest<SummaryBloc, SummaryState>(
    'reloads data when DataChangedEvent (expense) is received',
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => const Right(tExpenseSummary));
      return bloc;
    },
    act: (bloc) async {
      // First load to set state
      bloc.add(LoadSummary(startDate: tStartDate, endDate: tEndDate));
      // Wait for initial load to complete
      await Future.delayed(Duration.zero);
      // Trigger data change
      dataChangeStreamController.add(const DataChangedEvent(
          type: DataChangeType.expense, reason: DataChangeReason.added));
    },
    // We expect initial load sequence, then reload sequence
    // But since `act` is async and `blocTest` waits for stream to settle...
    // Let's just focus on the reload part by seeding?
    // But stream listener is in constructor.
    // If we seed, `_currentStartDate` is null.
    // Let's just verify the reload happens.
    skip: 0, // Don't skip
    expect: () => [
      const SummaryLoading(isReloading: false),
      const SummaryLoaded(tExpenseSummary),
      const SummaryLoading(isReloading: true, previousSummary: tExpenseSummary),
      const SummaryLoaded(tExpenseSummary),
    ],
  );

  blocTest<SummaryBloc, SummaryState>(
    'resets state when DataChangedEvent (reset) is received',
    seed: () => const SummaryLoaded(tExpenseSummary),
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => const Right(tExpenseSummary));
      return bloc;
    },
    act: (bloc) => dataChangeStreamController.add(const DataChangedEvent(
      type: DataChangeType.system,
      reason: DataChangeReason.reset,
    )),
    expect: () => [
      SummaryInitial(),
      const SummaryLoading(isReloading: false),
      const SummaryLoaded(tExpenseSummary),
    ],
  );
}
