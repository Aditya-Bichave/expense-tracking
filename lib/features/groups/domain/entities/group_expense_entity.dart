import 'package:equatable/equatable.dart';

class GroupExpenseEntity extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String currency;
  final DateTime occurredAt;
  final String createdBy;
  // Simplified for now, complex splits can be separate entities or nested
  // For V1, assume equal split or just basic record.
  // But requirements mention expense_payers and expense_splits.
  // I'll keep it simple for now and maybe add List<Payer> later.

  const GroupExpenseEntity({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [id, groupId, title, amount, currency, occurredAt, createdBy];
}
