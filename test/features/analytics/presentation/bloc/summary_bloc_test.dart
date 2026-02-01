import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetExpenseSummaryUseCase extends Mock implements GetExpenseSummaryUseCase {}

void main() {
  late MockGetExpenseSummaryUseCase mockGetExpenseSummaryUseCase;
  late StreamController<DataChangedEvent> dataChangeController;
  late SummaryBloc summaryBloc;

  setUpAll(() {
    registerFallbackValue(GetSummaryParams());
  });

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

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(summaryBloc.state, isA<SummaryInitial>());
    });

    final tSummary = const ExpenseSummary(
      totalExpenses: 100,
      categoryBreakdown: {'Test': 100},
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when LoadSummary is added and succeeds',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => Right(tSummary));
        return summaryBloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when LoadSummary fails',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => Left(UnexpectedFailure('Error')));
        return summaryBloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryError('An unexpected error occurred loading the summary.'),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] with isReloading=true when reloading',
      seed: () => SummaryLoaded(tSummary),
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => Right(tSummary));
        return summaryBloc;
      },
      act: (bloc) => bloc.add(const LoadSummary(forceReload: true)),
      expect: () => [
        const SummaryLoading(isReloading: true),
        SummaryLoaded(tSummary),
      ],
    );

    test('reloads data when DataChangedEvent is received', () async {
      when(() => mockGetExpenseSummaryUseCase(any()))
          .thenAnswer((_) async => Right(tSummary));

      summaryBloc.add(const LoadSummary());
      await untilCalled(() => mockGetExpenseSummaryUseCase(any()));

      dataChangeController.add(const DataChangedEvent(type: DataChangeType.expense, reason: DataChangeReason.updated));

      await Future.delayed(Duration.zero);
      verify(() => mockGetExpenseSummaryUseCase(any())).called(2);
    });

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryInitial, SummaryLoading, SummaryLoaded] when ResetState event is received via stream',
      build: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => Right(tSummary));
        return summaryBloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.system, reason: DataChangeReason.reset));
      },
       // The stream listener adds ResetState, which emits SummaryInitial and adds LoadSummary
      expect: () => [
        isA<SummaryInitial>(),
        const SummaryLoading(isReloading: false),
        SummaryLoaded(tSummary),
      ],
    );
  });
}
