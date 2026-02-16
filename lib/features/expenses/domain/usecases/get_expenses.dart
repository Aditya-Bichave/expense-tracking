import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
// Import logger

// Keep Params class if it's potentially used elsewhere, otherwise remove too.
class GetExpensesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category; // Category ID
  final String? accountId;

  const GetExpensesParams({
    this.startDate,
    this.endDate,
    this.category,
    this.accountId,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}

// --- Placeholder Failure for commented code ---
class NotImplementedFailure extends Failure {
  const NotImplementedFailure(String message) : super(message);
}
