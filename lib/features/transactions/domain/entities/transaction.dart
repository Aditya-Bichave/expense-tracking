import 'package:equatable/equatable.dart';

enum TransactionType { expense, income, transfer }

class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? fromAccountId;
  final String? toAccountId;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.fromAccountId,
    this.toAccountId,
  });

  @override
  List<Object?> get props => [id, type, amount, date, fromAccountId, toAccountId];
}
