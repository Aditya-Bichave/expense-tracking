import 'package:equatable/equatable.dart';

class Settlement extends Equatable {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final DateTime createdAt;

  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    groupId,
    fromUserId,
    toUserId,
    amount,
    currency,
    createdAt,
  ];
}
