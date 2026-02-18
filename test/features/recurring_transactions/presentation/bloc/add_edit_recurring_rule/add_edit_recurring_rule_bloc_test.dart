import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockAddRecurringRule extends Mock implements AddRecurringRule {}

class MockUpdateRecurringRule extends Mock implements UpdateRecurringRule {}

class MockUuid extends Mock implements Uuid {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeRecurringRule extends Fake implements RecurringRule {}

void main() {
  late AddEditRecurringRuleBloc bloc;
  late MockAddRecurringRule mockAddRecurringRule;
  late MockUpdateRecurringRule mockUpdateRecurringRule;
  late MockUuid mockUuid;
  late MockSettingsBloc mockSettingsBloc;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(FakeRecurringRule());
  });

  setUp(() {
    mockAddRecurringRule = MockAddRecurringRule();
    mockUpdateRecurringRule = MockUpdateRecurringRule();
    mockUuid = MockUuid();
    mockSettingsBloc = MockSettingsBloc();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    // Mock SettingsBloc state for currency parsing
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsState(
        selectedCountryCode: 'US',
        // selectedLanguageCode: 'en', // Removed as it is not in the constructor in memory
        themeMode: ThemeMode.system,
        uiMode: UIMode.elemental,
        // notificationsEnabled: true, // Removed
      ),
    );

    // Register mocks in GetIt
    if (GetIt.I.isRegistered<SettingsBloc>()) {
      GetIt.I.unregister<SettingsBloc>();
    }
    GetIt.I.registerSingleton<SettingsBloc>(mockSettingsBloc);

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

  final tCategory = Category(
    id: 'cat1',
    name: 'Food',
    iconName: 'food',
    colorHex: '0xFFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tRecurringRule = RecurringRule(
    id: '1',
    description: 'Rent',
    amount: 1000.0,
    frequency: Frequency.monthly,
    interval: 1,
    nextOccurrenceDate: DateTime.now(),
    startDate: DateTime(2023, 1, 1),
    status: RuleStatus.active,
    occurrencesGenerated: 0,
    categoryId: 'cat1',
    accountId: 'acc1',
    transactionType: TransactionType.expense,
    endConditionType: EndConditionType.never,
  );

  group('AddEditRecurringRuleBloc', () {
    test('initial state is correct', () {
      bloc = AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      );
      expect(bloc.state.status, FormStatus.initial);
      expect(bloc.state.isEditMode, false);
    });

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'InitializeForEdit emits state with rule details',
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      act: (bloc) => bloc.add(InitializeForEdit(tRecurringRule)),
      expect: () => [
        isA<AddEditRecurringRuleState>()
            .having((s) => s.isEditMode, 'isEditMode', true)
            .having(
              (s) => s.description,
              'description',
              tRecurringRule.description,
            )
            .having((s) => s.amount, 'amount', tRecurringRule.amount)
            .having((s) => s.accountId, 'accountId', tRecurringRule.accountId),
      ],
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'DescriptionChanged emits updated description',
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      act: (bloc) => bloc.add(const DescriptionChanged('New Desc')),
      expect: () => [
        isA<AddEditRecurringRuleState>().having(
          (s) => s.description,
          'description',
          'New Desc',
        ),
      ],
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'AmountChanged emits parsed amount',
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      act: (bloc) => bloc.add(const AmountChanged('123.45')),
      expect: () => [
        isA<AddEditRecurringRuleState>().having(
          (s) => s.amount,
          'amount',
          123.45,
        ),
      ],
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'CategoryChanged emits updated category',
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      act: (bloc) => bloc.add(CategoryChanged(tCategory)),
      expect: () => [
        isA<AddEditRecurringRuleState>()
            .having((s) => s.categoryId, 'categoryId', 'cat1')
            .having((s) => s.selectedCategory, 'selectedCategory', tCategory),
      ],
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'FormSubmitted emits failure if amount is invalid',
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      act: (bloc) =>
          bloc.add(const FormSubmitted(description: 'Desc', amount: '0')),
      expect: () => [
        isA<AddEditRecurringRuleState>().having(
          (s) => s.status,
          'status',
          FormStatus.inProgress,
        ),
        isA<AddEditRecurringRuleState>()
            .having((s) => s.status, 'status', FormStatus.failure)
            .having(
              (s) => s.errorMessage,
              'error',
              contains('valid, positive amount'),
            ),
      ],
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'FormSubmitted emits success when adding rule succeeds',
      setUp: () {
        when(() => mockUuid.v4()).thenReturn('newId');
        when(
          () => mockAddRecurringRule(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      seed: () => AddEditRecurringRuleState.initial().copyWith(
        accountId: 'acc1',
        categoryId: 'cat1',
        startDate: DateTime.now(),
      ),
      act: (bloc) =>
          bloc.add(const FormSubmitted(description: 'Desc', amount: '100')),
      expect: () => [
        isA<AddEditRecurringRuleState>().having(
          (s) => s.status,
          'status',
          FormStatus.inProgress,
        ),
        isA<AddEditRecurringRuleState>().having(
          (s) => s.status,
          'status',
          FormStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => mockAddRecurringRule(any())).called(1);
      },
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'FormSubmitted emits success when updating rule succeeds',
      setUp: () {
        when(
          () => mockUpdateRecurringRule(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => AddEditRecurringRuleBloc(
        addRecurringRule: mockAddRecurringRule,
        updateRecurringRule: mockUpdateRecurringRule,
        uuid: mockUuid,
      ),
      seed: () => AddEditRecurringRuleState.initial().copyWith(
        isEditMode: true,
        initialRule: tRecurringRule,
        accountId: 'acc1',
        categoryId: 'cat1',
        startDate: DateTime.now(),
      ),
      act: (bloc) =>
          bloc.add(const FormSubmitted(description: 'Desc', amount: '100')),
      expect: () => [
        isA<AddEditRecurringRuleState>().having(
          (s) => s.status,
          'status',
          FormStatus.inProgress,
        ),
        isA<AddEditRecurringRuleState>().having(
          (s) => s.status,
          'status',
          FormStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateRecurringRule(any())).called(1);
      },
    );
  });
}
