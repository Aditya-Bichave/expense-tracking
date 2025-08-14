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
      final rules = ruleModels.map((model) => model.toEntity()).toList();
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
      String ruleId) async {
    try {
      final logModels = await localDataSource.getAuditLogsForRule(ruleId);
      final logs = logModels.map((model) => model.toEntity()).toList();
      return Right(logs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
