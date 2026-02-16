import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';

class PauseResumeRecurringRule implements UseCase<void, String> {
  final RecurringTransactionRepository repository;
  final UpdateRecurringRule updateRecurringRule;

  PauseResumeRecurringRule({
    required this.repository,
    required this.updateRecurringRule,
  });

  @override
  Future<Either<Failure, void>> call(String ruleId) async {
    final ruleOrFailure = await repository.getRecurringRuleById(ruleId);
    return ruleOrFailure.fold((failure) => Left(failure), (rule) async {
      final newStatus = rule.status == RuleStatus.active
          ? RuleStatus.paused
          : RuleStatus.active;
      final updatedRule = rule.copyWith(status: newStatus);
      return await updateRecurringRule(updatedRule);
    });
  }
}
