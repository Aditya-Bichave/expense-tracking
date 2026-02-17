import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class UserHistoryLocalDataSource {
  /// Finds a specific rule based on its type and matcher string.
  Future<UserHistoryRuleModel?> findRule(String ruleType, String matcher);

  /// Saves or updates a rule. If a rule with the same type/matcher exists, it might be updated.
  Future<void> saveRule(UserHistoryRuleModel rule);

  /// Deletes a rule by its unique ruleId.
  Future<void> deleteRule(String ruleId);

  /// Retrieves all stored history rules (potentially for debugging or advanced management).
  Future<List<UserHistoryRuleModel>> getAllRules();

  /// Clears all history rules.
  Future<void> clearAllRules();
}

class HiveUserHistoryLocalDataSource implements UserHistoryLocalDataSource {
  final Box<UserHistoryRuleModel> historyBox;

  HiveUserHistoryLocalDataSource(this.historyBox);

  @override
  Future<void> deleteRule(String ruleId) async {
    try {
      // Assuming ruleId is the key used in Hive. If not, need to find the key first.
      await historyBox.delete(ruleId);
      log.info("Deleted user history rule (ID: $ruleId) from Hive.");
    } catch (e, s) {
      log.severe(
        "Failed to delete user history rule (ID: $ruleId) from cache$e$s",
      );
      throw CacheFailure('Failed to delete history rule: ${e.toString()}');
    }
  }

  @override
  Future<UserHistoryRuleModel?> findRule(
    String ruleType,
    String matcher,
  ) async {
    try {
      // Hive boxes aren't easily queryable like SQL. We need to iterate.
      // This could be slow for very large history sets. Consider optimization if needed.
      for (var rule in historyBox.values) {
        if (rule.ruleType == ruleType && rule.matcher == matcher) {
          log.info(
            "Found matching user history rule. Type: $ruleType, Matcher: $matcher, CategoryId: ${rule.assignedCategoryId}",
          );
          return rule;
        }
      }
      log.fine(
        "No matching user history rule found for Type: $ruleType, Matcher: $matcher",
      );
      return null; // Not found
    } catch (e, s) {
      log.severe("Failed to query user history rules from cache$e$s");
      throw CacheFailure('Failed to find history rule: ${e.toString()}');
    }
  }

  @override
  Future<List<UserHistoryRuleModel>> getAllRules() async {
    try {
      final rules = historyBox.values.toList();
      log.info("Retrieved ${rules.length} user history rules from Hive.");
      return rules;
    } catch (e, s) {
      log.severe("Failed to get all user history rules from cache$e$s");
      throw CacheFailure('Failed to get history rules: ${e.toString()}');
    }
  }

  @override
  Future<void> saveRule(UserHistoryRuleModel rule) async {
    try {
      // Simple approach: Use ruleId as the key. Assumes ruleId is unique.
      await historyBox.put(rule.ruleId, rule);
      log.info(
        "Saved/Updated user history rule (ID: ${rule.ruleId}, Type: ${rule.ruleType}, Matcher: ${rule.matcher}) to Hive.",
      );
    } catch (e, s) {
      log.severe(
        "Failed to save user history rule (ID: ${rule.ruleId}) to cache$e$s",
      );
      throw CacheFailure('Failed to save history rule: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllRules() async {
    try {
      final count = await historyBox.clear();
      log.info(
        "Cleared user history rules box in Hive ($count items removed).",
      );
    } catch (e, s) {
      log.severe("Failed to clear user history rules cache$e$s");
      throw CacheFailure(
        'Failed to clear history rules cache: ${e.toString()}',
      );
    }
  }
}
