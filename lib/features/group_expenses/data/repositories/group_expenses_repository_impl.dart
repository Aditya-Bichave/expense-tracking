import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_remote_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';

class GroupExpensesRepositoryImpl implements GroupExpensesRepository {
  final GroupExpensesLocalDataSource _localDataSource;
  final GroupExpensesRemoteDataSource _remoteDataSource;
  final OutboxRepository _outboxRepository;
  final SyncService _syncService;
  final Connectivity _connectivity;

  GroupExpensesRepositoryImpl({
    required GroupExpensesLocalDataSource localDataSource,
    required GroupExpensesRemoteDataSource remoteDataSource,
    required OutboxRepository outboxRepository,
    required SyncService syncService,
    required Connectivity connectivity,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _outboxRepository = outboxRepository,
       _syncService = syncService,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, GroupExpense>> addExpense(GroupExpense expense) async {
    try {
      final model = GroupExpenseModel.fromEntity(expense);
      await _localDataSource.saveExpense(model);

      final outboxItem = SyncMutationModel(
        id: expense.id,
        table: 'expenses', // Assumed table name
        operation: OpType.create,
        payload: model.toJson(),
        createdAt: DateTime.now(),
      );
      await _outboxRepository.add(outboxItem);

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        _syncService.processOutbox();
      }

      return Right(expense);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupExpense>>> getExpenses(
    String groupId,
  ) async {
    try {
      final models = _localDataSource.getExpenses(groupId);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncExpenses(String groupId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return const Right(null);
      }

      final remoteExpenses = await _remoteDataSource.getExpenses(groupId);
      await _localDataSource.saveExpenses(remoteExpenses);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
