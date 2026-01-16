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
  late SummaryBloc summaryBloc;

  setUpAll(() {
    registerFallbackValue(FakeGetSummaryParams());
  });
  late MockGetExpenseSummaryUseCase mockGetExpenseSummaryUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  setUp(() {
    mockGetExpenseSummaryUseCase = MockGetExpenseSummaryUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();
    summaryBloc = SummaryBloc(
      getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    summaryBloc.close();
    dataChangeController.close();
  });

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  test('initial state should be SummaryInitial', () {
    expect(summaryBloc.state, equals(SummaryInitial()));
  });

  group('LoadSummary', () {
    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when data is gotten successfully',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
        return summaryBloc;
      },
      act: (bloc) => bloc.add(LoadSummary(
          startDate: tStartDate, endDate: tEndDate, updateFilters: true)),
      verify: (bloc) {
        verify(() => mockGetExpenseSummaryUseCase(tParams)).called(1);
      },
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tExpenseSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when getting data fails',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Cache Error')));
        return summaryBloc;
      },
      act: (bloc) => bloc.add(LoadSummary(
          startDate: tStartDate, endDate: tEndDate, updateFilters: true)),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryError(
            'Could not load summary from local data. Cache Error'),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] with isReloading=true when reloading',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
        return summaryBloc;
      },
      seed: () => const SummaryLoaded(tExpenseSummary),
      act: (bloc) => bloc.add(const LoadSummary(forceReload: true)),
      expect: () => [
        const SummaryLoading(isReloading: true),
        const SummaryLoaded(tExpenseSummary),
      ],
    );
  });

  group('DataChangedEvent', () {
    blocTest<SummaryBloc, SummaryState>(
      'triggers reload when relevant DataChangedEvent is received',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
        return summaryBloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.added));
        // Wait a bit for the listener to react
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tExpenseSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'triggers ResetState when system reset event is received',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
        return summaryBloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.system, reason: DataChangeReason.reset));
        // Wait a bit for the listener to react
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        SummaryInitial(),
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tExpenseSummary),
      ],
    );
  });
}
