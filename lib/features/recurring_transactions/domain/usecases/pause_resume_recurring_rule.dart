import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/core/services/auth_service.dart';

class PauseResumeRecurringRule implements UseCase<void, String> {
  final RecurringTransactionRepository repository;
  final UpdateRecurringRule updateRecurringRule;
  final AuthService authService;

  PauseResumeRecurringRule({
    required this.repository,
    required this.updateRecurringRule,
    required this.authService,
  });

  @override
  Future<Either<Failure, void>> call(String ruleId) async {
    final ruleOrFailure = await repository.getRecurringRuleById(ruleId);
    return ruleOrFailure.fold((failure) => Left(failure), (rule) async {
      final newStatus = rule.status == RuleStatus.active
          ? RuleStatus.paused
          : RuleStatus.active;
      final updatedRule = rule.copyWith(status: newStatus);
      final userId = authService.getCurrentUserId();
      return await updateRecurringRule(
        UpdateRecurringRuleParams(newRule: updatedRule, userId: userId),
      );
    });
  }
}
