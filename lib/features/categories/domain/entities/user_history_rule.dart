import 'package:equatable/equatable.dart';

enum RuleType { merchant, description }

class UserHistoryRule extends Equatable {
  final String id; // UUID
  final RuleType ruleType;
  final String matcher; // Merchant ID or description hash/pattern
  final String assignedCategoryId; // ID of the category to assign
  final DateTime timestamp;

  const UserHistoryRule({
    required this.id,
    required this.ruleType,
    required this.matcher,
    required this.assignedCategoryId,
    required this.timestamp,
  });

  @override
  List<Object?> get props =>
      [id, ruleType, matcher, assignedCategoryId, timestamp];
}
