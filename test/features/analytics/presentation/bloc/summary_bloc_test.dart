
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

class MockDataChangedEvent extends Mock implements DataChangedEvent {}

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

  final tSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: const {},
    // dailyExpenses removed as it was not in the entity
  );

  test('initial state is SummaryInitial', () {
    expect(bloc.state, isA<SummaryInitial>());
  });

  group('LoadSummary', () {
    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when success',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        isA<SummaryLoading>(),
        SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when failure',
      setUp: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Error')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        isA<SummaryLoading>(),
        isA<SummaryError>(),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'updates filters when updateFilters is true',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadSummary(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 31),
        updateFilters: true,
      )),
      expect: () => [
        isA<SummaryLoading>(),
        SummaryLoaded(tSummary),
      ],
      verify: (_) {
        verify(() => mockUseCase(GetSummaryParams(
              startDate: DateTime(2023, 1, 1),
              endDate: DateTime(2023, 1, 31),
            ))).called(1);
      },
    );
  });

  group('DataChangedEvent', () {
    blocTest<SummaryBloc, SummaryState>(
      'reloads data when relevant DataChangedEvent is received',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));
      },
      build: () => bloc,
      act: (bloc) {
        dataChangeStreamController.add(DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        ));
      },
      // Wait for the async event processing
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SummaryLoading>(),
        SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'resets state when system reset event is received',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));
      },
      build: () => bloc,
      act: (bloc) {
        dataChangeStreamController.add(DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        ));
      },
       wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SummaryInitial>(),
        isA<SummaryLoading>(),
        SummaryLoaded(tSummary),
      ],
    );
  });

  group('ResetState', () {
    blocTest<SummaryBloc, SummaryState>(
      'emits SummaryInitial and then reloads',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const ResetState()),
      expect: () => [
        isA<SummaryInitial>(),
        isA<SummaryLoading>(),
        SummaryLoaded(tSummary),
      ],
    );
  });
}
