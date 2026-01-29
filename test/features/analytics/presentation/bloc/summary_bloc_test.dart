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

void main() {
  late MockGetExpenseSummaryUseCase mockGetExpenseSummaryUseCase;
  late StreamController<DataChangedEvent> dataChangeController;
  late SummaryBloc bloc;

  setUp(() {
    mockGetExpenseSummaryUseCase = MockGetExpenseSummaryUseCase();
    dataChangeController = StreamController<DataChangedEvent>();
    bloc = SummaryBloc(
      getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
      dataChangeStream: dataChangeController.stream,
    );
    registerFallbackValue(const GetSummaryParams());
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  const tSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(bloc.state, isA<SummaryInitial>());
    });

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when LoadSummary is added and succeeds',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when LoadSummary fails',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryError('Could not load summary from local data. A local data storage error occurred.'),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when DataChangedEvent triggers reload',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      seed: () => const SummaryLoaded(tSummary),
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.updated,
        ));
      },
      expect: () => [
        const SummaryLoading(isReloading: true, previousSummary: tSummary),
        const SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'resets state when ResetState is added (triggered by system reset event)',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
             .thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      seed: () => const SummaryLoaded(tSummary),
      act: (bloc) async {
         dataChangeController.add(const DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        ));
      },
      expect: () => [
        isA<SummaryInitial>(),
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tSummary),
      ],
    );
  });
}
