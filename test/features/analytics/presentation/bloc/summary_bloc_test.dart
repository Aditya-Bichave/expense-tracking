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

  setUp(() {
    mockGetExpenseSummaryUseCase = MockGetExpenseSummaryUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();
    registerFallbackValue(const GetSummaryParams());
  });

  tearDown(() {
    dataChangeController.close();
  });

  SummaryBloc buildBloc() {
    return SummaryBloc(
      getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  }

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {},
  );

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(buildBloc().state, SummaryInitial());
    });

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when LoadSummary is added and succeeds',
      build: buildBloc,
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tExpenseSummary),
      ],
      verify: (_) {
        verify(() => mockGetExpenseSummaryUseCase(any())).called(1);
      },
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when LoadSummary is added and fails',
      build: buildBloc,
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Left(UnexpectedFailure('Error')));
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryError('An unexpected error occurred loading the summary.'),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryInitial, SummaryLoading, SummaryLoaded] when ResetState is added',
      build: buildBloc,
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
      },
      act: (bloc) => bloc.add(const ResetState()),
      expect: () => [
        SummaryInitial(),
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tExpenseSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'reloads data when DataChangedEvent is received via stream',
      build: buildBloc,
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
      },
      act: (bloc) async {
        bloc.add(const LoadSummary());
        // Wait for first load to finish
        await Future.delayed(Duration.zero);
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.added));
      },
      // Skip the initial load states to focus on re-load
      skip: 2,
      expect: () => [
        const SummaryLoading(isReloading: true),
        const SummaryLoaded(tExpenseSummary),
      ],
    );
    blocTest<SummaryBloc, SummaryState>(
      'resets state when DataChangedEvent(reset) is received via stream',
      build: buildBloc,
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.system, reason: DataChangeReason.reset));
      },
      expect: () => [
        SummaryInitial(),
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tExpenseSummary),
      ],
    );
  });
}
