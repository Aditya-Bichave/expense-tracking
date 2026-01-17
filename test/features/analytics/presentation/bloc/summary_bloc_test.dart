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

class MockDataChangeStream extends Mock implements Stream<DataChangedEvent> {}

void main() {
  late SummaryBloc summaryBloc;
  late MockGetExpenseSummaryUseCase mockGetExpenseSummaryUseCase;
  late Stream<DataChangedEvent> dataChangeStream;
  // Using a broadcast controller to simulate the stream
  late dynamic streamController;

  setUp(() {
    mockGetExpenseSummaryUseCase = MockGetExpenseSummaryUseCase();
    // In Dart tests, we can use a StreamController to verify stream subscriptions
    // However, Bloc takes a Stream. We will use a controller to pump events.
    // For now we just pass a stream.
    // Ideally we want to control the stream.
  });

  setUpAll(() {
    registerFallbackValue(const GetSummaryParams());
  });

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      summaryBloc = SummaryBloc(
        getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
        dataChangeStream: const Stream.empty(),
      );
      expect(summaryBloc.state, equals(SummaryInitial()));
      summaryBloc.close();
    });

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when LoadSummary is added and use case succeeds',
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
      },
      build: () => SummaryBloc(
        getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
        dataChangeStream: const Stream.empty(),
      ),
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
      'emits [SummaryLoading, SummaryError] when LoadSummary is added and use case fails',
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any())).thenAnswer(
            (_) async => const Left(UnexpectedFailure('Unexpected error')));
      },
      build: () => SummaryBloc(
        getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
        dataChangeStream: const Stream.empty(),
      ),
      act: (bloc) => bloc.add(const LoadSummary()),
      expect: () => [
        const SummaryLoading(isReloading: false),
        const SummaryError('An unexpected error occurred loading the summary.'),
      ],
    );

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when reloading',
      setUp: () {
        when(() => mockGetExpenseSummaryUseCase(any()))
            .thenAnswer((_) async => const Right(tExpenseSummary));
      },
      build: () => SummaryBloc(
        getExpenseSummaryUseCase: mockGetExpenseSummaryUseCase,
        dataChangeStream: const Stream.empty(),
      ),
      seed: () => const SummaryLoaded(tExpenseSummary),
      act: (bloc) => bloc.add(const LoadSummary(forceReload: true)),
      expect: () => [
        const SummaryLoading(isReloading: true),
        const SummaryLoaded(tExpenseSummary),
      ],
    );
  });
}
