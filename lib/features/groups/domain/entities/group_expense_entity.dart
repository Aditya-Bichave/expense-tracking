import 'package:equatable/equatable.dart';

class GroupExpenseEntity extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String currency;
  final DateTime occurredAt;
  final String createdBy;
  final String? notes;

  const GroupExpenseEntity({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.createdBy,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    groupId,
    title,
    amount,
    currency,
    occurredAt,
    createdBy,
    notes,
  ];
}
