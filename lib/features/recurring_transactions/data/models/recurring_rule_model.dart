import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hive_ce/hive.dart';

part 'recurring_rule_model.g.dart';

@HiveType(typeId: 10) // Placeholder TypeId
class RecurringRuleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? userId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String categoryId;

  @HiveField(5)
  final String accountId;

  @HiveField(6)
  final int transactionTypeIndex;

  @HiveField(7)
  final int frequencyIndex;

  @HiveField(8)
  final int interval;

  @HiveField(9)
  final DateTime startDate;

  @HiveField(10)
  final int? dayOfWeek;

  @HiveField(11)
  final int? dayOfMonth;

  @HiveField(12)
  final int endConditionTypeIndex;

  @HiveField(13)
  final DateTime? endDate;

  @HiveField(14)
  final int? totalOccurrences;

  @HiveField(15)
  final int statusIndex;

  @HiveField(16)
  final DateTime nextOccurrenceDate;

  @HiveField(17)
  final int occurrencesGenerated;

  RecurringRuleModel({
    required this.id,
    this.userId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.accountId,
    required this.transactionTypeIndex,
    required this.frequencyIndex,
    required this.interval,
    required this.startDate,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.endConditionTypeIndex,
    this.endDate,
    this.totalOccurrences,
    required this.statusIndex,
    required this.nextOccurrenceDate,
    required this.occurrencesGenerated,
  });

  factory RecurringRuleModel.fromEntity(RecurringRule entity) {
    return RecurringRuleModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      description: entity.description,
      categoryId: entity.categoryId,
      accountId: entity.accountId,
      transactionTypeIndex: entity.transactionType.index,
      frequencyIndex: entity.frequency.index,
      interval: entity.interval,
      startDate: entity.startDate,
      dayOfWeek: entity.dayOfWeek,
      dayOfMonth: entity.dayOfMonth,
      endConditionTypeIndex: entity.endConditionType.index,
      endDate: entity.endDate,
      totalOccurrences: entity.totalOccurrences,
      statusIndex: entity.status.index,
      nextOccurrenceDate: entity.nextOccurrenceDate,
      occurrencesGenerated: entity.occurrencesGenerated,
    );
  }

  RecurringRule toEntity() {
    return RecurringRule(
      id: id,
      userId: userId,
      amount: amount,
      description: description,
      categoryId: categoryId,
      accountId: accountId,
      transactionType: TransactionType.values[transactionTypeIndex],
      frequency: Frequency.values[frequencyIndex],
      interval: interval,
      startDate: startDate,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      endConditionType: EndConditionType.values[endConditionTypeIndex],
      endDate: endDate,
      totalOccurrences: totalOccurrences,
      status: RuleStatus.values[statusIndex],
      nextOccurrenceDate: nextOccurrenceDate,
      occurrencesGenerated: occurrencesGenerated,
    );
  }
}
