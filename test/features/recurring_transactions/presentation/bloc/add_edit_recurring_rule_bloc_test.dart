import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockAddRecurringRule extends Mock implements AddRecurringRule {}
class MockUpdateRecurringRule extends Mock implements UpdateRecurringRule {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late AddEditRecurringRuleBloc bloc;
  late MockAddRecurringRule mockAddRecurringRule;
  late MockUpdateRecurringRule mockUpdateRecurringRule;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(RecurringRule(
      id: '',
      description: '',
      amount: 0,
      transactionType: TransactionType.expense,
      accountId: '',
      categoryId: '',
      frequency: Frequency.monthly,
      interval: 1,
      startDate: DateTime.now(),
      endConditionType: EndConditionType.never,
      status: RuleStatus.active,
      nextOccurrenceDate: DateTime.now(),
      occurrencesGenerated: 0,
    ));
  });

  setUp(() {
    mockAddRecurringRule = MockAddRecurringRule();
    mockUpdateRecurringRule = MockUpdateRecurringRule();
    mockUuid = MockUuid();
    bloc = AddEditRecurringRuleBloc(
      addRecurringRule: mockAddRecurringRule,
      updateRecurringRule: mockUpdateRecurringRule,
      uuid: mockUuid,
    );
  });

  final tRule = RecurringRule(
    id: '1',
    description: 'Netflix',
    amount: 15.99,
    transactionType: TransactionType.expense,
    accountId: 'acc1',
    categoryId: 'cat1',
    frequency: Frequency.monthly,
    interval: 1,
    startDate: DateTime(2023, 1, 15),
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime(2023, 2, 15),
    occurrencesGenerated: 1,
  );

  const tCategory = Category(
    id: 'cat1',
    name: 'Subscriptions',
    iconName: 'subscriptions',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  test('initial state is correct', () {
    expect(bloc.state, AddEditRecurringRuleState.initial());
  });

  group('FormSubmitted', () {
    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'should call AddRecurringRule when creating a new rule',
      setUp: () {
        when(() => mockUuid.v4()).thenReturn('new_id');
        when(() => mockAddRecurringRule(any())).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) {
        bloc.add(const DescriptionChanged('Test'));
        bloc.add(const AmountChanged('100'));
        bloc.add(const AccountChanged('acc1'));
        bloc.add(CategoryChanged(tCategory));
        bloc.add(FormSubmitted());
      },
      expect: () => [
        isA<AddEditRecurringRuleState>().having((s) => s.description, 'description', 'Test'),
        isA<AddEditRecurringRuleState>().having((s) => s.amount, 'amount', 100.0),
        isA<AddEditRecurringRuleState>().having((s) => s.accountId, 'accountId', 'acc1'),
        isA<AddEditRecurringRuleState>()
            .having((s) => s.categoryId, 'categoryId', tCategory.id),
        isA<AddEditRecurringRuleState>().having((s) => s.status, 'status', FormStatus.inProgress),
        isA<AddEditRecurringRuleState>().having((s) => s.status, 'status', FormStatus.success),
      ],
      verify: (_) {
        verify(() => mockAddRecurringRule(any())).called(1);
      },
    );

    blocTest<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
      'should call UpdateRecurringRule when editing an existing rule',
      setUp: () {
        when(() => mockUpdateRecurringRule(any())).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      seed: () => AddEditRecurringRuleState.initial().copyWith(
        isEditMode: true,
        initialRule: tRule,
        accountId: tRule.accountId,
        categoryId: tRule.categoryId,
        description: tRule.description,
        amount: tRule.amount,
      ),
      act: (bloc) => bloc.add(FormSubmitted()),
      expect: () => [
        isA<AddEditRecurringRuleState>().having((s) => s.status, 'status', FormStatus.inProgress),
        isA<AddEditRecurringRuleState>().having((s) => s.status, 'status', FormStatus.success),
      ],
      verify: (_) {
        verify(() => mockUpdateRecurringRule(any())).called(1);
      },
    );
  });
}
