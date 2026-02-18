import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/features/settlements/data/datasources/settlements_local_data_source.dart';
import 'package:expense_tracker/features/settlements/data/datasources/settlements_remote_data_source.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement_entity.dart';
import 'package:expense_tracker/features/settlements/domain/repositories/settlements_repository.dart';
import 'package:uuid/uuid.dart';

class SettlementsRepositoryImpl implements SettlementsRepository {
  final SettlementsLocalDataSource _localDataSource;
  final SettlementsRemoteDataSource _remoteDataSource;
  final OutboxRepository _outboxRepository;
  final Uuid _uuid;

  SettlementsRepositoryImpl({
    required SettlementsLocalDataSource localDataSource,
    required SettlementsRemoteDataSource remoteDataSource,
    required OutboxRepository outboxRepository,
    required Uuid uuid,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _outboxRepository = outboxRepository,
       _uuid = uuid;

  @override
  Future<Either<Failure, List<SettlementEntity>>> getSettlements(
    String groupId,
  ) async {
    try {
      final local = _localDataSource.getSettlements(groupId);
      return Right(local.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementEntity>> addSettlement(
    SettlementEntity settlement,
  ) async {
    try {
      final model = SettlementModel.fromEntity(settlement);
      await _localDataSource.addSettlement(model);

      final outboxItem = OutboxItem(
        id: _uuid.v4(),
        entityType: EntityType.settlement,
        opType: OpType.create,
        payloadJson: jsonEncode(model.toJson()),
        createdAt: DateTime.now(),
        entityId: model.id,
      );
      await _outboxRepository.add(outboxItem);

      publishDataChangedEvent(
        type: DataChangeType.initialLoad,
        reason: DataChangeReason.localChange,
      );

      return Right(settlement);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncSettlements(String groupId) async {
    try {
      final remote = await _remoteDataSource.getSettlements(groupId);
      await _localDataSource.cacheSettlements(remote);
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
