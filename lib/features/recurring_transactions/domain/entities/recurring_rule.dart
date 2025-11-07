import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'recurring_rule_enums.dart';

class RecurringRule extends Equatable {
  final String id;
  final String? userId; // Nullable if not used for multi-user scenarios yet
  final double amount;
  final String description;
  final String categoryId;
  final String accountId;
  final TransactionType transactionType;
  final Frequency frequency;
  final int interval;
  final DateTime startDate;
  final int? dayOfWeek; // 1=Monday, 7=Sunday
  final int? dayOfMonth; // 1-31
  final EndConditionType endConditionType;
  final DateTime? endDate;
  final int? totalOccurrences;
  final RuleStatus status;
  final DateTime nextOccurrenceDate;
  final int occurrencesGenerated;

  const RecurringRule({
    required this.id,
    this.userId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.accountId,
    required this.transactionType,
    required this.frequency,
    required this.interval,
    required this.startDate,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.endConditionType,
    this.endDate,
    this.totalOccurrences,
    required this.status,
    required this.nextOccurrenceDate,
    required this.occurrencesGenerated,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        description,
        categoryId,
        accountId,
        transactionType,
        frequency,
        interval,
        startDate,
        dayOfWeek,
        dayOfMonth,
        endConditionType,
        endDate,
        totalOccurrences,
        status,
        nextOccurrenceDate,
        occurrencesGenerated,
      ];

  RecurringRule copyWith({
    String? id,
    String? userId,
    double? amount,
    String? description,
    String? categoryId,
    String? accountId,
    TransactionType? transactionType,
    Frequency? frequency,
    int? interval,
    DateTime? startDate,
    int? dayOfWeek,
    int? dayOfMonth,
    EndConditionType? endConditionType,
    DateTime? endDate,
    int? totalOccurrences,
    RuleStatus? status,
    DateTime? nextOccurrenceDate,
    int? occurrencesGenerated,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transactionType: transactionType ?? this.transactionType,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      endConditionType: endConditionType ?? this.endConditionType,
      endDate: endDate ?? this.endDate,
      totalOccurrences: totalOccurrences ?? this.totalOccurrences,
      status: status ?? this.status,
      nextOccurrenceDate: nextOccurrenceDate ?? this.nextOccurrenceDate,
      occurrencesGenerated: occurrencesGenerated ?? this.occurrencesGenerated,
    );
  }
}
