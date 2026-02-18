import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_expenses_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/group_expenses_repository.dart';
import 'package:uuid/uuid.dart';

class GroupExpensesRepositoryImpl implements GroupExpensesRepository {
  final GroupExpensesLocalDataSource _localDataSource;
  final GroupExpensesRemoteDataSource _remoteDataSource;
  final OutboxRepository _outboxRepository;
  final Uuid _uuid;

  GroupExpensesRepositoryImpl({
    required GroupExpensesLocalDataSource localDataSource,
    required GroupExpensesRemoteDataSource remoteDataSource,
    required OutboxRepository outboxRepository,
    required Uuid uuid,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _outboxRepository = outboxRepository,
       _uuid = uuid;

  @override
  Future<Either<Failure, List<GroupExpenseEntity>>> getExpenses(
    String groupId,
  ) async {
    try {
      final local = _localDataSource.getExpensesForGroup(groupId);
      // Trigger sync?
      // syncExpenses(groupId);
      return Right(local.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupExpenseEntity>> addExpense(
    GroupExpenseEntity expense,
  ) async {
    try {
      final model = GroupExpenseModel.fromEntity(expense);
      await _localDataSource.addExpense(model);

      final outboxItem = OutboxItem(
        id: _uuid.v4(),
        entityType: EntityType.groupExpense,
        opType: OpType.create,
        payloadJson: jsonEncode(model.toJson()),
        createdAt: DateTime.now(),
        entityId: model.id,
      );
      await _outboxRepository.add(outboxItem);

      publishDataChangedEvent(
        type: DataChangeType.transactionAdded,
        reason: DataChangeReason.localChange,
      );

      return Right(expense);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncExpenses(String groupId) async {
    try {
      final remote = await _remoteDataSource.getExpenses(groupId);
      await _localDataSource.cacheExpenses(remote);
      publishDataChangedEvent(
        type: DataChangeType.initialLoad,
        reason: DataChangeReason.remoteSync,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
