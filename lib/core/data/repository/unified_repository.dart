import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// A Unified Repository that handles Local-First data management.
///
/// It writes to a local Hive Box immediately (optimistic UI) and queues
/// the operation to the [OutboxRepository] for background synchronization
/// with Supabase.
abstract class UnifiedRepository<Model extends HiveObject> {
  final Box<Model> localBox;
  final OutboxRepository outboxRepository;
  final Uuid uuid;

  UnifiedRepository({
    required this.localBox,
    required this.outboxRepository,
    this.uuid = const Uuid(),
  });

  /// Adds an item to local storage and queues an INSERT op.
  Future<Either<Failure, T>> add<T extends Model>(
    T item, {
    required String tableName,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      // 1. Save to local Hive box
      await localBox.add(item);
      // Note: Hive might not set 'id' if using auto-increment int keys,
      // but our models usually use UUID strings.

      final entityId = (item as dynamic).id as String; // Explicitly cast to String

      // 2. Queue to Outbox
      final outboxItem = OutboxItem(
        id: uuid.v4(),
        entityId: entityId,
        entityType: _mapTableNameToEntityType(tableName),
        opType: OpType.create, // Enum uses 'create', not 'insert'
        payloadJson: jsonEncode(toJson(item)),
        createdAt: DateTime.now(),
      );
      await outboxRepository.add(outboxItem);

      return Right(item);
    } catch (e) {
      return Left(CacheFailure('Unified Add Error: $e'));
    }
  }

  /// Updates an item in local storage and queues an UPDATE op.
  Future<Either<Failure, T>> update<T extends Model>(
    T item, {
    required String tableName,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      // 1. Save to local Hive box
      await item.save();

      final entityId = (item as dynamic).id as String;

      // 2. Queue to Outbox
      final outboxItem = OutboxItem(
        id: uuid.v4(),
        entityId: entityId,
        entityType: _mapTableNameToEntityType(tableName),
        opType: OpType.update,
        payloadJson: jsonEncode(toJson(item)),
        createdAt: DateTime.now(),
      );
      await outboxRepository.add(outboxItem);

      return Right(item);
    } catch (e) {
      return Left(CacheFailure('Unified Update Error: $e'));
    }
  }

  /// Deletes an item from local storage and queues a DELETE op.
  Future<Either<Failure, void>> delete(
    Model item, {
    required String tableName,
  }) async {
    try {
      final id = (item as dynamic).id as String;

      // 1. Delete from local Hive box
      await item.delete();

      // 2. Queue to Outbox
      final outboxItem = OutboxItem(
        id: uuid.v4(),
        entityId: id,
        entityType: _mapTableNameToEntityType(tableName),
        opType: OpType.delete,
        payloadJson: jsonEncode({'id': id}),
        createdAt: DateTime.now(),
      );
      await outboxRepository.add(outboxItem);

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Unified Delete Error: $e'));
    }
  }

  EntityType _mapTableNameToEntityType(String tableName) {
    switch (tableName) {
      case 'groups': return EntityType.group;
      case 'group_members': return EntityType.groupMember;
      case 'group_expenses': return EntityType.groupExpense;
      case 'expenses': return EntityType.expense;
      case 'income': return EntityType.income;
      default: return EntityType.groupExpense; // Fallback or throw
    }
  }
}
