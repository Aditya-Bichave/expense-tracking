import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/utils/currency_parser.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'add_edit_recurring_rule_event.dart';
part 'add_edit_recurring_rule_state.dart';

class AddEditRecurringRuleBloc
    extends Bloc<AddEditRecurringRuleEvent, AddEditRecurringRuleState> {
  final AddRecurringRule addRecurringRule;
  final UpdateRecurringRule updateRecurringRule;
  final Uuid uuid;

  AddEditRecurringRuleBloc({
    required this.addRecurringRule,
    required this.updateRecurringRule,
    required this.uuid,
  }) : super(AddEditRecurringRuleState.initial()) {
    on<InitializeForEdit>(_onInitializeForEdit);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<AmountChanged>(_onAmountChanged);
    on<TransactionTypeChanged>(_onTransactionTypeChanged);
    on<AccountChanged>(_onAccountChanged);
    on<CategoryChanged>(_onCategoryChanged);
    on<FrequencyChanged>(_onFrequencyChanged);
    on<IntervalChanged>(_onIntervalChanged);
    on<StartDateChanged>(_onStartDateChanged);
    on<EndConditionTypeChanged>(_onEndConditionTypeChanged);
    on<EndDateChanged>(_onEndDateChanged);
    on<TotalOccurrencesChanged>(_onTotalOccurrencesChanged);
    on<DayOfWeekChanged>(_onDayOfWeekChanged);
    on<DayOfMonthChanged>(_onDayOfMonthChanged);
    on<TimeChanged>(_onTimeChanged);
    on<FormSubmitted>(_onFormSubmitted);
  }

  void _onInitializeForEdit(
    InitializeForEdit event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(
      state.copyWith(
        isEditMode: true,
        initialRule: event.rule,
        description: event.rule.description,
        amount: event.rule.amount,
        transactionType: event.rule.transactionType,
        accountId: event.rule.accountId,
        categoryId: event.rule.categoryId,
        frequency: event.rule.frequency,
        interval: event.rule.interval,
        startDate: event.rule.startDate,
        startTime: TimeOfDay.fromDateTime(event.rule.startDate),
        dayOfWeek: event.rule.dayOfWeek,
        dayOfMonth: event.rule.dayOfMonth,
        endConditionType: event.rule.endConditionType,
        endDate: event.rule.endDate,
        totalOccurrences: event.rule.totalOccurrences,
      ),
    );
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onAmountChanged(
    AmountChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    final locale = sl<SettingsBloc>().state.selectedCountryCode;
    final amount = parseCurrency(event.amount, locale);
    emit(state.copyWith(amount: amount.isNaN ? 0.0 : amount));
  }

  void _onTransactionTypeChanged(
    TransactionTypeChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(
      state.copyWith(
        transactionType: event.transactionType,
        categoryId: null,
        selectedCategory: null,
      ),
    );
  }

  void _onAccountChanged(
    AccountChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(accountId: event.accountId));
  }

  void _onCategoryChanged(
    CategoryChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(
      state.copyWith(
        categoryId: event.category.id,
        selectedCategory: event.category,
      ),
    );
  }

  void _onFrequencyChanged(
    FrequencyChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(frequency: event.frequency));
  }

  void _onIntervalChanged(
    IntervalChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(interval: int.tryParse(event.interval) ?? 1));
  }

  void _onStartDateChanged(
    StartDateChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(startDate: event.startDate));
  }

  void _onEndConditionTypeChanged(
    EndConditionTypeChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(endConditionType: event.endConditionType));
  }

  void _onEndDateChanged(
    EndDateChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(endDate: event.endDate));
  }

  void _onTotalOccurrencesChanged(
    TotalOccurrencesChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(
      state.copyWith(totalOccurrences: int.tryParse(event.occurrences) ?? 0),
    );
  }

  void _onDayOfWeekChanged(
    DayOfWeekChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(dayOfWeek: event.dayOfWeek));
  }

  void _onDayOfMonthChanged(
    DayOfMonthChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(dayOfMonth: event.dayOfMonth));
  }

  void _onTimeChanged(
    TimeChanged event,
    Emitter<AddEditRecurringRuleState> emit,
  ) {
    emit(state.copyWith(startTime: event.time));
  }

// After
  Future<void> _onFormSubmitted(
      FormSubmitted event,
      Emitter<AddEditRecurringRuleState> emit,
      ) async {
    emit(state.copyWith(status: FormStatus.inProgress));

    // --- PARSE AND VALIDATE THE AMOUNT HERE ---
    final locale = sl<SettingsBloc>().state.selectedCountryCode;
    final amount = parseCurrency(event.amount, locale);

    if (amount.isNaN || amount <= 0) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Please enter a valid, positive amount.',
        ),
      );
      return;
    }
    // --- END PARSING AND VALIDATION ---

    if (state.accountId == null || state.categoryId == null) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Please select an account and a category.',
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      state.startDate.year,
      state.startDate.month,
      state.startDate.day,
      state.startTime?.hour ?? 0,
      state.startTime?.minute ?? 0,
    );

    final ruleToSave = RecurringRule(
      id: state.isEditMode ? state.initialRule!.id : uuid.v4(),
      description: event.description, // Use fresh data from the event
      amount: amount,                 // Use the newly parsed amount
      transactionType: state.transactionType,
      accountId: state.accountId!,
      categoryId: state.categoryId!,
      frequency: state.frequency,
      interval: state.interval,
      startDate: startDateTime,
      dayOfWeek: state.dayOfWeek,
      dayOfMonth: state.dayOfMonth,
      endConditionType: state.endConditionType,
      endDate: state.endDate,
      totalOccurrences: state.totalOccurrences,
      status: state.isEditMode ? state.initialRule!.status : RuleStatus.active,
      nextOccurrenceDate: state.isEditMode
          ? state.initialRule!.nextOccurrenceDate
          : startDateTime,
      occurrencesGenerated:
      state.isEditMode ? state.initialRule!.occurrencesGenerated : 0,
    );

    final result = state.isEditMode
        ? await updateRecurringRule(ruleToSave)
        : await addRecurringRule(ruleToSave);

    result.fold(
          (failure) => emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
          (_) {
        publishDataChangedEvent(
          type: DataChangeType.recurringRule,
          reason: state.isEditMode
              ? DataChangeReason.updated
              : DataChangeReason.added,
        );
        emit(state.copyWith(status: FormStatus.success));
      },
    );
  }
}
