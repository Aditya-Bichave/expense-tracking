import 'package:equatable/equatable.dart';
import 'income_category.dart';

class Income extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final IncomeCategory category;
  final String accountId; // Link to AssetAccount
  final String? notes;

  const Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountId,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [id, title, amount, date, category, accountId, notes];
}
