import 'package:equatable/equatable.dart';

class ExpenseSummary extends Equatable {
  final double totalExpenses;
  final Map<String, double> categoryBreakdown; // Category name to total amount

  const ExpenseSummary({
    required this.totalExpenses,
    required this.categoryBreakdown,
  });

  @override
  List<Object?> get props => [totalExpenses, categoryBreakdown];
}
