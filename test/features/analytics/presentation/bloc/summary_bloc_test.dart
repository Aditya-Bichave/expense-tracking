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
  late SummaryBloc bloc;
  late MockGetExpenseSummaryUseCase mockUseCase;
  late StreamController<DataChangedEvent> dataChangeStreamController;

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

  test('initial state is SummaryInitial', () {
    expect(bloc.state, isA<SummaryInitial>());
  });

  group('LoadSummary', () {
    const tSummary = ExpenseSummary(
      totalExpenses: 100,
      categoryBreakdown: {'Food': 100},
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when usecase succeeds',
      build: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when usecase fails',
      build: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryError('Server Error'),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] with isReloading=true when already loaded and forced',
      seed: () => const SummaryLoaded(tSummary),
      build: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary(forceReload: true)),
      expect: () => [
        const SummaryLoading(isReloading: true),
        const SummaryLoaded(tSummary),
      ],
    );
  });

  group('DataChangedEvent', () {
    const tSummary = ExpenseSummary(
      totalExpenses: 200,
      categoryBreakdown: {'Food': 200},
    );

    test('triggers reload when expense data changes', () async {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right(tSummary));

      // Trigger the event via stream
      dataChangeStreamController.add(
        const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.updated,
        ),
      );

      // Wait for async processing
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const SummaryLoading(isReloading: false),
          const SummaryLoaded(tSummary),
        ]),
      );
    });

    test('triggers ResetState when system reset happens', () async {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right(tSummary));

      dataChangeStreamController.add(
        const DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        ),
      );

      // Should go to Initial, then Loading -> Loaded (because ResetState triggers LoadSummary)
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryInitial>(),
          const SummaryLoading(isReloading: false),
          const SummaryLoaded(tSummary),
        ]),
      );
    });
  });
}
