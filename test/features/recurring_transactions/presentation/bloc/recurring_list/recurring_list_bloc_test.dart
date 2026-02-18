import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/delete_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rules.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/pause_resume_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockGetRecurringRules extends Mock implements GetRecurringRules {}

class MockPauseResumeRecurringRule extends Mock
    implements PauseResumeRecurringRule {}

class MockDeleteRecurringRule extends Mock implements DeleteRecurringRule {}

void main() {
  late RecurringListBloc bloc;
  late MockGetRecurringRules mockGetRecurringRules;
  late MockPauseResumeRecurringRule mockPauseResumeRecurringRule;
  late MockDeleteRecurringRule mockDeleteRecurringRule;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockGetRecurringRules = MockGetRecurringRules();
    mockPauseResumeRecurringRule = MockPauseResumeRecurringRule();
    mockDeleteRecurringRule = MockDeleteRecurringRule();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    // Default stub for getRecurringRules to avoid Null errors when LoadRecurringRules is triggered indirectly
    when(
      () => mockGetRecurringRules(any()),
    ).thenAnswer((_) async => const Right([]));

    // Register StreamController in GetIt for publishDataChangedEvent
    if (GetIt.I.isRegistered<StreamController<DataChangedEvent>>(
      instanceName: 'dataChangeController',
    )) {
      GetIt.I.unregister<StreamController<DataChangedEvent>>(
        instanceName: 'dataChangeController',
      );
    }
    GetIt.I.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );
  });

  tearDown(() {
    dataChangeController.close();
    GetIt.I.reset();
  });

  final tRecurringRule = RecurringRule(
    id: '1',
    description: 'Rent',
    amount: 1000.0,
    frequency: Frequency.monthly,
    interval: 1,
    nextOccurrenceDate: DateTime.now(),
    startDate: DateTime.now(),
    status: RuleStatus.active,
    occurrencesGenerated: 0,
    categoryId: 'cat1',
    accountId: 'acc1',
    transactionType: TransactionType.expense,
    endConditionType: EndConditionType.never,
  );

  blocTest<RecurringListBloc, RecurringListState>(
    'emits [Loading, Loaded] when LoadRecurringRules is added and succeeds',
    build: () {
      when(
        () => mockGetRecurringRules(any()),
      ).thenAnswer((_) async => Right([tRecurringRule]));
      return RecurringListBloc(
        getRecurringRules: mockGetRecurringRules,
        pauseResumeRecurringRule: mockPauseResumeRecurringRule,
        deleteRecurringRule: mockDeleteRecurringRule,
        dataChangedEventStream: dataChangeController.stream,
      );
    },
    act: (bloc) => bloc.add(LoadRecurringRules()),
    expect: () => [
      RecurringListLoading(),
      RecurringListLoaded([tRecurringRule]),
    ],
  );

  blocTest<RecurringListBloc, RecurringListState>(
    'emits [Loading, Error] when LoadRecurringRules fails',
    build: () {
      when(
        () => mockGetRecurringRules(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('Error')));
      return RecurringListBloc(
        getRecurringRules: mockGetRecurringRules,
        pauseResumeRecurringRule: mockPauseResumeRecurringRule,
        deleteRecurringRule: mockDeleteRecurringRule,
        dataChangedEventStream: dataChangeController.stream,
      );
    },
    act: (bloc) => bloc.add(LoadRecurringRules()),
    expect: () => [RecurringListLoading(), const RecurringListError('Error')],
  );

  blocTest<RecurringListBloc, RecurringListState>(
    'calls PauseResumeUseCase when PauseResumeRule is added',
    build: () {
      when(
        () => mockPauseResumeRecurringRule(any()),
      ).thenAnswer((_) async => const Right(null));
      return RecurringListBloc(
        getRecurringRules: mockGetRecurringRules,
        pauseResumeRecurringRule: mockPauseResumeRecurringRule,
        deleteRecurringRule: mockDeleteRecurringRule,
        dataChangedEventStream: dataChangeController.stream,
      );
    },
    act: (bloc) => bloc.add(const PauseResumeRule('1')),
    verify: (_) {
      verify(() => mockPauseResumeRecurringRule('1')).called(1);
    },
  );

  blocTest<RecurringListBloc, RecurringListState>(
    'calls DeleteRecurringRule when DeleteRule is added',
    build: () {
      when(
        () => mockDeleteRecurringRule(any()),
      ).thenAnswer((_) async => const Right(null));
      return RecurringListBloc(
        getRecurringRules: mockGetRecurringRules,
        pauseResumeRecurringRule: mockPauseResumeRecurringRule,
        deleteRecurringRule: mockDeleteRecurringRule,
        dataChangedEventStream: dataChangeController.stream,
      );
    },
    act: (bloc) => bloc.add(const DeleteRule('1')),
    verify: (_) {
      verify(() => mockDeleteRecurringRule('1')).called(1);
    },
  );

  blocTest<RecurringListBloc, RecurringListState>(
    'reloads when DataChangedEvent type is recurringRule',
    build: () {
      when(
        () => mockGetRecurringRules(any()),
      ).thenAnswer((_) async => Right([tRecurringRule]));
      return RecurringListBloc(
        getRecurringRules: mockGetRecurringRules,
        pauseResumeRecurringRule: mockPauseResumeRecurringRule,
        deleteRecurringRule: mockDeleteRecurringRule,
        dataChangedEventStream: dataChangeController.stream,
      );
    },
    act: (bloc) {
      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.recurringRule,
          reason: DataChangeReason.updated,
        ),
      );
    },
    expect: () => [
      RecurringListLoading(),
      RecurringListLoaded([tRecurringRule]),
    ],
  );
}
