import 'package:equatable/equatable.dart';

enum SplitType {
  equal,
  percent,
  exact;

  String get value => name;
  static SplitType fromValue(String value) => SplitType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SplitType.equal,
  );
}

class ExpensePayer extends Equatable {
  final String userId;
  final double amount;

  const ExpensePayer({required this.userId, required this.amount});

  @override
  List<Object?> get props => [userId, amount];
}

class ExpenseSplit extends Equatable {
  final String userId;
  final double amount;
  final SplitType splitType;

  const ExpenseSplit({
    required this.userId,
    required this.amount,
    required this.splitType,
  });

  @override
  List<Object?> get props => [userId, amount, splitType];
}

class GroupExpense extends Equatable {
  final String id;
  final String groupId;
  final String createdBy;
  final String title;
  final double amount;
  final String currency;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<ExpensePayer> payers;
  final List<ExpenseSplit> splits;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.payers = const [],
    this.splits = const [],
  });

  @override
  List<Object?> get props => [
    id,
    groupId,
    createdBy,
    title,
    amount,
    currency,
    occurredAt,
    createdAt,
    updatedAt,
    payers,
    splits,
  ];
}
