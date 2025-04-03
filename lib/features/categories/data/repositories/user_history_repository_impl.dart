import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/user_history_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/main.dart'; // logger

class UserHistoryRepositoryImpl implements UserHistoryRepository {
  final UserHistoryLocalDataSource localDataSource;

  UserHistoryRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, UserHistoryRule?>> findRule(
      RuleType type, String matcher) async {
    log.fine(
        "[UserHistoryRepo] findRule called. Type: ${type.name}, Matcher: $matcher");
    try {
      final model = await localDataSource.findRule(type.name, matcher);
      if (model != null) {
        log.fine("[UserHistoryRepo] Rule found. ID: ${model.ruleId}");
        return Right(model.toEntity());
      } else {
        log.fine("[UserHistoryRepo] No rule found.");
        return const Right(null); // Explicitly return null if not found
      }
    } on CacheFailure catch (e) {
      log.warning(
          "[UserHistoryRepo] CacheFailure during findRule: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[UserHistoryRepo] Unexpected error in findRule$e$s");
      return Left(CacheFailure("Failed to find history rule: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> saveRule(UserHistoryRule rule) async {
    log.info(
        "[UserHistoryRepo] saveRule called for rule ID: ${rule.id}, Type: ${rule.ruleType.name}");
    try {
      // Overwrite existing rule based on type/matcher before saving new one?
      // Current DS logic uses rule.id as key, so need to find existing first if we want to overwrite by type/matcher.
      final existingRuleResult = await findRule(rule.ruleType, rule.matcher);
      if (existingRuleResult.isRight()) {
        final existingRule = existingRuleResult.getOrElse(() => null);
        if (existingRule != null && existingRule.id != rule.id) {
          log.info(
              "[UserHistoryRepo] Deleting existing rule ${existingRule.id} before saving new one ${rule.id}.");
          await localDataSource.deleteRule(existingRule.id);
        }
      } // Ignore failure during find, proceed to save new rule

      final model = UserHistoryRuleModel.fromEntity(rule);
      await localDataSource.saveRule(model);
      log.info("[UserHistoryRepo] Rule saved successfully.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[UserHistoryRepo] CacheFailure during saveRule: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[UserHistoryRepo] Unexpected error in saveRule$e$s");
      return Left(CacheFailure("Failed to save history rule: ${e.toString()}"));
    }
  }
}
