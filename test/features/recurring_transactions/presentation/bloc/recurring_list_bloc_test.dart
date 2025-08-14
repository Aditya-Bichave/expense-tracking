import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
// for NoParams
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/delete_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rules.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/pause_resume_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGetRecurringRules extends Mock implements GetRecurringRules {}

class MockPauseResumeRecurringRule extends Mock
    implements PauseResumeRecurringRule {}

class MockDeleteRecurringRule extends Mock implements DeleteRecurringRule {}

void main() {
  late MockGetRecurringRules mockGetRecurringRules;
  late MockPauseResumeRecurringRule mockPauseResumeRecurringRule;
  late MockDeleteRecurringRule mockDeleteRecurringRule;
  late RecurringListBloc recurringListBloc;
  late StreamController<DataChangedEvent> dataChangeController;

  setUp(() async {
    mockGetRecurringRules = MockGetRecurringRules();
    mockPauseResumeRecurringRule = MockPauseResumeRecurringRule();
    mockDeleteRecurringRule = MockDeleteRecurringRule();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    await sl.reset();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);

    recurringListBloc = RecurringListBloc(
      getRecurringRules: mockGetRecurringRules,
      pauseResumeRecurringRule: mockPauseResumeRecurringRule,
      deleteRecurringRule: mockDeleteRecurringRule,
      dataChangedEventStream: dataChangeController.stream,
    );
  });

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  tearDown(() async {
    await recurringListBloc.close();
    await dataChangeController.close();
    await sl.reset();
  });

  group('RecurringListBloc', () {
    final tRecurringRule = RecurringRule(
      id: '1',
      description: 'Test Rule',
      amount: 100,
      transactionType: TransactionType.expense,
      frequency: Frequency.monthly,
      interval: 1,
      startDate: DateTime.now(),
      endConditionType: EndConditionType.never,
      status: RuleStatus.active,
      nextOccurrenceDate: DateTime.now(),
      occurrencesGenerated: 0,
      accountId: 'acc1',
      categoryId: 'cat1',
    );
    final tRecurringRules = [tRecurringRule];

    test('initial state should be RecurringListInitial', () {
      expect(recurringListBloc.state, RecurringListInitial());
    });

    blocTest<RecurringListBloc, RecurringListState>(
      'emits [RecurringListLoading, RecurringListLoaded] when LoadRecurringRules is added.',
      build: () {
        when(
          () => mockGetRecurringRules(any()),
        ).thenAnswer((_) async => Right(tRecurringRules));
        return recurringListBloc;
      },
      act: (bloc) => bloc.add(LoadRecurringRules()),
      expect: () => [
        RecurringListLoading(),
        RecurringListLoaded(tRecurringRules),
      ],
    );

    blocTest<RecurringListBloc, RecurringListState>(
      'emits [RecurringListError] when GetRecurringRules fails.',
      build: () {
        when(
          () => mockGetRecurringRules(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Error')));
        return recurringListBloc;
      },
      act: (bloc) => bloc.add(LoadRecurringRules()),
      expect: () => [RecurringListLoading(), const RecurringListError('Error')],
    );

    blocTest<RecurringListBloc, RecurringListState>(
      'calls PauseResumeRecurringRule and reloads list on success',
      build: () {
        when(
          () => mockPauseResumeRecurringRule(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetRecurringRules(any()),
        ).thenAnswer((_) async => Right(tRecurringRules));
        return recurringListBloc;
      },
      act: (bloc) => bloc.add(const PauseResumeRule('1')),
      verify: (_) {
        verify(() => mockPauseResumeRecurringRule('1')).called(1);
        verify(() => mockGetRecurringRules(any())).called(1);
      },
    );

    blocTest<RecurringListBloc, RecurringListState>(
      'calls DeleteRecurringRule and reloads list on success',
      build: () {
        when(
          () => mockDeleteRecurringRule(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetRecurringRules(any()),
        ).thenAnswer((_) async => Right(tRecurringRules));
        return recurringListBloc;
      },
      act: (bloc) => bloc.add(const DeleteRule('1')),
      verify: (_) {
        verify(() => mockDeleteRecurringRule('1')).called(1);
        verify(() => mockGetRecurringRules(any())).called(1);
      },
    );

    blocTest<RecurringListBloc, RecurringListState>(
      'resets and reloads when system reset DataChangedEvent is received',
      build: () {
        when(
          () => mockGetRecurringRules(any()),
        ).thenAnswer((_) async => Right(tRecurringRules));
        return recurringListBloc;
      },
      act: (bloc) {
        dataChangeController.add(
          const DataChangedEvent(
            type: DataChangeType.system,
            reason: DataChangeReason.reset,
          ),
        );
      },
      expect: () => [
        RecurringListInitial(),
        RecurringListLoading(),
        RecurringListLoaded(tRecurringRules),
      ],
    );

    blocTest<RecurringListBloc, RecurringListState>(
      'reloads when system updated DataChangedEvent is received',
      build: () {
        when(
          () => mockGetRecurringRules(any()),
        ).thenAnswer((_) async => Right(tRecurringRules));
        return recurringListBloc;
      },
      act: (bloc) {
        dataChangeController.add(
          const DataChangedEvent(
            type: DataChangeType.system,
            reason: DataChangeReason.updated,
          ),
        );
      },
      expect: () => [
        RecurringListLoading(),
        RecurringListLoaded(tRecurringRules),
      ],
    );
  });
}
