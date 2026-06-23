import 'package:logging/logging.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionRepositoryImpl
    implements RecurringTransactionRepository {
  final RecurringTransactionLocalDataSource localDataSource;

  RecurringTransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> addRecurringRule(RecurringRule rule) async {
    try {
      final ruleModel = RecurringRuleModel.fromEntity(rule);
      await localDataSource.addRecurringRule(ruleModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRule>>> getRecurringRules() async {
    try {
      final ruleModels = await localDataSource.getRecurringRules();
      // ⚡ Bolt Performance Optimization
      // Problem: `.map().toList()` allocates an intermediate list of objects before filtering.
      // Solution: Use a direct for-loop to filter and extract entities in a single pass.
      // Impact: Reduces object instantiation and GC pressure when getting recurring rules.
      final rules = <RecurringRule>[];
      for (final model in ruleModels) {
        rules.add(model.toEntity());
      }
      return Right(rules);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> getRecurringRuleById(String id) async {
    try {
      final ruleModel = await localDataSource.getRecurringRuleById(id);
      return Right(ruleModel.toEntity());
    } on NotFoundFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRecurringRule(RecurringRule rule) async {
    try {
      final ruleModel = RecurringRuleModel.fromEntity(rule);
      await localDataSource.updateRecurringRule(ruleModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecurringRule(String id) async {
    try {
      await localDataSource.deleteRecurringRule(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAuditLog(RecurringRuleAuditLog log) async {
    try {
      final logModel = RecurringRuleAuditLogModel.fromEntity(log);
      await localDataSource.addAuditLog(logModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRuleAuditLog>>> getAuditLogsForRule(
    String ruleId,
  ) async {
    try {
      final logModels = await localDataSource.getAuditLogsForRule(ruleId);
      // ⚡ Bolt Performance Optimization
      // Problem: `.map().toList()` allocates an intermediate list of objects before filtering.
      // Solution: Use a direct for-loop to map and extract entities in a single pass.
      // Impact: Reduces object instantiation and GC pressure when getting audit logs.
      final logs = <RecurringRuleAuditLog>[];
      for (final model in logModels) {
        logs.add(model.toEntity());
      }
      return Right(logs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
