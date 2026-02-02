
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetExpenseSummaryUseCase extends Mock
    implements GetExpenseSummaryUseCase {}

class FakeGetSummaryParams extends Fake implements GetSummaryParams {}

void main() {
  late SummaryBloc bloc;
  late MockGetExpenseSummaryUseCase mockGetSummary;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(FakeGetSummaryParams());
  });

  setUp(() {
    mockGetSummary = MockGetExpenseSummaryUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = SummaryBloc(
      getExpenseSummaryUseCase: mockGetSummary,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  const tSummary = ExpenseSummary(
    totalExpenses: 50.0,
    categoryBreakdown: {'Food': 20.0, 'Transport': 30.0},
  );

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(bloc.state, SummaryInitial());
    });

    group('LoadSummary', () {
      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryLoaded] when successful',
        build: () {
          when(() => mockGetSummary(any()))
              .thenAnswer((_) async => const Right(tSummary));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSummary()),
        expect: () => [
          const SummaryLoading(isReloading: false),
          const SummaryLoaded(tSummary),
        ],
        verify: (_) {
          verify(() => mockGetSummary(any())).called(1);
        },
      );

      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryError] when failure',
        build: () {
          when(() => mockGetSummary(any())).thenAnswer(
              (_) async => const Left(UnexpectedFailure('Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSummary()),
        expect: () => [
          const SummaryLoading(isReloading: false),
          const SummaryError('An unexpected error occurred loading the summary.'),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'updates filters when updateFilters is true',
        build: () {
          when(() => mockGetSummary(any()))
              .thenAnswer((_) async => const Right(tSummary));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadSummary(
          startDate: DateTime(2023, 1, 1),
          endDate: DateTime(2023, 1, 31),
          updateFilters: true,
        )),
        expect: () => [
          const SummaryLoading(isReloading: false),
          const SummaryLoaded(tSummary),
        ],
        verify: (_) {
          final captured = verify(() => mockGetSummary(captureAny())).captured;
          final params = captured.first as GetSummaryParams;
          expect(params.startDate, DateTime(2023, 1, 1));
          expect(params.endDate, DateTime(2023, 1, 31));
        },
      );
    });

    group('DataChangedEvent', () {
      blocTest<SummaryBloc, SummaryState>(
        'reloads summary when expense data changes',
        build: () {
          when(() => mockGetSummary(any()))
              .thenAnswer((_) async => const Right(tSummary));
          return bloc;
        },
        act: (bloc) {
          dataChangeController.add(const DataChangedEvent(
              type: DataChangeType.expense, reason: DataChangeReason.updated));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const SummaryLoading(isReloading: false),
          const SummaryLoaded(tSummary),
        ],
      );
    });

    group('ResetState', () {
      blocTest<SummaryBloc, SummaryState>(
        'resets state and reloads',
        build: () {
          when(() => mockGetSummary(any()))
              .thenAnswer((_) async => const Right(tSummary));
          return bloc;
        },
        act: (bloc) => bloc.add(const ResetState()),
        expect: () => [
          SummaryInitial(),
          const SummaryLoading(isReloading: false),
          const SummaryLoaded(tSummary),
        ],
      );
    });
  });
}
