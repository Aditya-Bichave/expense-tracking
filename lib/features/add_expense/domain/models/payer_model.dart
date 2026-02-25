import 'package:equatable/equatable.dart';

class PayerModel extends Equatable {
  final String userId;
  final double amountPaid;

  const PayerModel({required this.userId, required this.amountPaid});

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'amount_paid': amountPaid,
  };

  @override
  List<Object?> get props => [userId, amountPaid];
}
