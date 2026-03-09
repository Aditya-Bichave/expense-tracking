import 'package:equatable/equatable.dart';

class SimplifiedDebt extends Equatable {
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String fromUserName;
  final String toUserName;
  final String? toUserUpi;

  const SimplifiedDebt({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.fromUserName,
    required this.toUserName,
    this.toUserUpi,
  });

  factory SimplifiedDebt.fromJson(Map<String, dynamic> json) {
    return SimplifiedDebt(
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      fromUserName: json['from_user_name'] as String,
      toUserName: json['to_user_name'] as String,
      toUserUpi: json['to_user_upi'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    fromUserId,
    toUserId,
    amount,
    fromUserName,
    toUserName,
    toUserUpi,
  ];
}
