import 'package:equatable/equatable.dart';

class ExpensePayer extends Equatable {
  final String userId;
  final double amountPaid;

  const ExpensePayer({required this.userId, required this.amountPaid});

  @override
  List<Object?> get props => [userId, amountPaid];
}
