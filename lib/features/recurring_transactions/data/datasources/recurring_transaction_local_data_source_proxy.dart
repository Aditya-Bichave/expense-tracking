import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:expense_tracker/core/utils/logger.dart';

class DemoAwareRecurringTransactionDataSource
    implements RecurringTransactionLocalDataSource {
  final RecurringTransactionLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareRecurringTransactionDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<void> addRecurringRule(RecurringRuleModel rule) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareRecurringDS] Adding demo rule: ${rule.description}");
      return demoModeService.addDemoRecurringRule(rule);
    } else {
      return hiveDataSource.addRecurringRule(rule);
    }
  }

  @override
  Future<List<RecurringRuleModel>> getRecurringRules() async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareRecurringDS] Getting demo rules.");
      return demoModeService.getDemoRecurringRules();
    } else {
      return hiveDataSource.getRecurringRules();
    }
  }

  @override
  Future<RecurringRuleModel> getRecurringRuleById(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareRecurringDS] Getting demo rule ID: $id");
      final rule = await demoModeService.getDemoRecurringRuleById(id);
      if (rule != null) {
        return rule;
      }
      throw Exception('Demo recurring rule not found');
    } else {
      return hiveDataSource.getRecurringRuleById(id);
    }
  }

  @override
  Future<void> updateRecurringRule(RecurringRuleModel rule) async {
    if (demoModeService.isDemoActive) {
      log.fine(
        "[DemoAwareRecurringDS] Updating demo rule: ${rule.description}",
      );
      return demoModeService.updateDemoRecurringRule(rule);
    } else {
      return hiveDataSource.updateRecurringRule(rule);
    }
  }

  @override
  Future<void> deleteRecurringRule(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareRecurringDS] Deleting demo rule ID: $id");
      return demoModeService.deleteDemoRecurringRule(id);
    } else {
      return hiveDataSource.deleteRecurringRule(id);
    }
  }

  @override
  Future<void> addAuditLog(RecurringRuleAuditLogModel log) async {
    if (demoModeService.isDemoActive) {
      // For demo mode, we can just store logs in memory or ignore them
      // Storing in memory is better for completeness
      return demoModeService.addDemoRecurringAuditLog(log);
    } else {
      return hiveDataSource.addAuditLog(log);
    }
  }

  @override
  Future<List<RecurringRuleAuditLogModel>> getAuditLogsForRule(
    String ruleId,
  ) async {
    if (demoModeService.isDemoActive) {
      return demoModeService.getDemoRecurringAuditLogsForRule(ruleId);
    } else {
      return hiveDataSource.getAuditLogsForRule(ruleId);
    }
  }
}
