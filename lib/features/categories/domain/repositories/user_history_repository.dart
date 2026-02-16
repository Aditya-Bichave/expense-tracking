import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';

abstract class UserHistoryRepository {
  /// Finds a rule matching the type and matcher string.
  Future<Either<Failure, UserHistoryRule?>> findRule(
    RuleType type,
    String matcher,
  );

  /// Saves or updates a user history rule.
  Future<Either<Failure, void>> saveRule(UserHistoryRule rule);

  // Optional: Add delete/getAll if needed for advanced management
  // Future<Either<Failure, void>> deleteRule(String ruleId);
  // Future<Either<Failure, List<UserHistoryRule>>> getAllRules();
}
