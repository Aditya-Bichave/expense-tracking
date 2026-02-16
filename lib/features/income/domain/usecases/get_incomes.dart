import 'package:equatable/equatable.dart';
// Import logger

class GetIncomesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId;

  const GetIncomesParams({
    this.startDate,
    this.endDate,
    this.category,
    this.accountId,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}
