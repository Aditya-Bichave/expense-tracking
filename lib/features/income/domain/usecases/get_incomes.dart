import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class GetIncomesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId;

  const GetIncomesParams(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}
