part of 'add_edit_recurring_rule_bloc.dart';

enum FormStatus { initial, inProgress, success, failure }

class AddEditRecurringRuleState extends Equatable {
  final RecurringRule? initialRule;
  final String description;
  final double amount;
  final TransactionType transactionType;
  final String? accountId;
  final String? categoryId;
  final Category? selectedCategory;

  // Recurrence Rule Data
  final Frequency frequency;
  final int interval;
  final DateTime startDate;
  final TimeOfDay? startTime;
  final int? dayOfWeek;
  final int? dayOfMonth;

  // End Condition Data
  final EndConditionType endConditionType;
  final DateTime? endDate;
  final int? totalOccurrences;

  // Form Status
  final FormStatus status;
  final String? errorMessage;
  final bool isEditMode;

  const AddEditRecurringRuleState({
    this.initialRule,
    this.description = '',
    this.amount = 0.0,
    this.transactionType = TransactionType.expense,
    this.accountId,
    this.categoryId,
    this.selectedCategory,
    this.frequency = Frequency.monthly,
    this.interval = 1,
    required this.startDate,
    this.startTime,
    this.dayOfWeek,
    this.dayOfMonth,
    this.endConditionType = EndConditionType.never,
    this.endDate,
    this.totalOccurrences,
    this.status = FormStatus.initial,
    this.errorMessage,
    this.isEditMode = false,
  });

  factory AddEditRecurringRuleState.initial() {
    final now = DateTime.now();
    return AddEditRecurringRuleState(
      startDate: now,
      startTime: TimeOfDay.fromDateTime(now),
    );
  }

  AddEditRecurringRuleState copyWith({
    RecurringRule? initialRule,
    String? description,
    double? amount,
    TransactionType? transactionType,
    String? accountId,
    String? categoryId,
    Category? selectedCategory,
    Frequency? frequency,
    int? interval,
    DateTime? startDate,
    TimeOfDay? startTime,
    int? dayOfWeek,
    int? dayOfMonth,
    EndConditionType? endConditionType,
    DateTime? endDate,
    int? totalOccurrences,
    FormStatus? status,
    String? errorMessage,
    bool? isEditMode,
  }) {
    return AddEditRecurringRuleState(
      initialRule: initialRule ?? this.initialRule,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      endConditionType: endConditionType ?? this.endConditionType,
      endDate: endDate ?? this.endDate,
      totalOccurrences: totalOccurrences ?? this.totalOccurrences,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  @override
  List<Object?> get props => [
    initialRule,
    description,
    amount,
    transactionType,
    accountId,
    categoryId,
    selectedCategory,
    frequency,
    interval,
    startDate,
    startTime,
    dayOfWeek,
    dayOfMonth,
    endConditionType,
    endDate,
    totalOccurrences,
    status,
    errorMessage,
    isEditMode,
  ];
}
