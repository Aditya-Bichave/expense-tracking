import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:hive/hive.dart';
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

  String _composeKey(String ruleType, String matcher) => '${ruleType}_$matcher';

  @override
  Future<void> deleteRule(String ruleId) async {
    try {
      final key = historyBox.keys.firstWhere(
        (k) => historyBox.get(k)!.ruleId == ruleId,
        orElse: () => null,
      );
      if (key != null) {
        await historyBox.delete(key);
        log.info("Deleted user history rule (ID: $ruleId) from Hive.");
      }
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
      final key = _composeKey(ruleType, matcher);
      final rule = historyBox.get(key);
      if (rule != null) {
        log.info(
          "Found matching user history rule. Type: $ruleType, Matcher: $matcher, CategoryId: ${rule.assignedCategoryId}",
        );
        return rule;
      }
      log.fine(
        "No matching user history rule found for Type: $ruleType, Matcher: $matcher",
      );
      return null;
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
      final key = _composeKey(rule.ruleType, rule.matcher);
      await historyBox.put(key, rule);
      log.info(
        "Saved/Updated user history rule (ID: ${rule.ruleId}, Type: ${rule.ruleType}, Matcher: ${rule.matcher}) to Hive with key $key.",
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
