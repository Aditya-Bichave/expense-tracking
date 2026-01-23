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

class MockGetExpenseSummaryUseCase extends Mock implements GetExpenseSummaryUseCase {}

class FakeGetSummaryParams extends Fake implements GetSummaryParams {}

void main() {
  late SummaryBloc bloc;
  late MockGetExpenseSummaryUseCase mockUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(FakeGetSummaryParams());
  });

  setUp(() {
    mockUseCase = MockGetExpenseSummaryUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();
    bloc = SummaryBloc(
      getExpenseSummaryUseCase: mockUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  const tSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {},
  );

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(bloc.state, SummaryInitial());
    });

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when LoadSummary is added and succeeds',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        SummaryLoading(isReloading: false),
        const SummaryLoaded(tSummary),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryError] when LoadSummary fails',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(CacheFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        SummaryLoading(isReloading: false),
        isA<SummaryError>(),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'reloads data when DataChangedEvent is received',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const LoadSummary());
        await Future.delayed(Duration.zero); // Wait for event processing
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.updated));
      },
      skip: 2, // Skip initial loading and loaded
      expect: () => [
        SummaryLoading(isReloading: true),
        const SummaryLoaded(tSummary),
      ],
    );

     blocTest<SummaryBloc, SummaryState>(
      'resets state when ResetState event is added',
      build: () {
         when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      seed: () => const SummaryLoaded(tSummary),
      act: (bloc) => bloc.add(const ResetState()),
      expect: () => [
        SummaryInitial(),
        SummaryLoading(isReloading: false),
        const SummaryLoaded(tSummary),
      ],
    );
  });
}
