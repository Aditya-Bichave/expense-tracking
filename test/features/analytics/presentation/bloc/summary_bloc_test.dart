import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class MockGetExpenseSummaryUseCase extends Mock
    implements GetExpenseSummaryUseCase {}

class MockExpenseSummary extends Mock implements ExpenseSummary {}

void main() {
  late MockGetExpenseSummaryUseCase mockUseCase;
  late StreamController<DataChangedEvent> dataChangeController;
  late SummaryBloc bloc;

  setUpAll(() {
    registerFallbackValue(GetSummaryParams(startDate: null, endDate: null));
  });

  setUp(() {
    mockUseCase = MockGetExpenseSummaryUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = SummaryBloc(
      getExpenseSummaryUseCase: mockUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() async {
    await bloc.close();
    await dataChangeController.close();
  });

  final tSummary = MockExpenseSummary();

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(bloc.state, isA<SummaryInitial>());
    });

    test('LoadSummary emits loading then loaded on success', () async {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryLoaded>().having((s) => s.summary, 'summary', tSummary),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;

      verify(() => mockUseCase(any())).called(1);
    });

    test('LoadSummary emits loading then error on CacheFailure', () async {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('cache error')));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            'Could not load summary from local data. cache error',
          ),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;
    });

    test('LoadSummary emits loading then error on UnexpectedFailure', () async {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Left(UnexpectedFailure('error')));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            'An unexpected error occurred loading the summary.',
          ),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;
    });

    test('LoadSummary handles exceptions gracefully', () async {
      when(() => mockUseCase(any())).thenThrow(Exception('crash'));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            contains(
              'An unexpected error occurred loading summary: Exception: crash',
            ),
          ),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;
    });

    test('data change stream triggers reset on system reset event', () async {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryInitial>(),
          isA<SummaryLoading>(),
          isA<SummaryLoaded>(),
        ]),
      );

      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        ),
      );

      await future;
    });

    test('data change stream triggers reload on expense data change', () async {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tSummary));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(), // Forced reload
          isA<SummaryLoaded>(),
        ]),
      );

      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        ),
      );

      await future;
    });
  });
}
