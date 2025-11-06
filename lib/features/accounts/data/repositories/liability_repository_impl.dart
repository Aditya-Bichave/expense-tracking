import 'package:dartz/dartz.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/datasources/liability_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/liability_model.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/liability_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';

class LiabilityRepositoryImpl implements LiabilityRepository {
  final LiabilityLocalDataSource localDataSource;
  final TransactionRepository transactionRepository;

  LiabilityRepositoryImpl({
    required this.localDataSource,
    required this.transactionRepository,
  });

  @override
  Future<Either<Failure, Liability>> addLiability(Liability liability) async {
    try {
      final liabilityModel = LiabilityModel.fromEntity(liability);
      await localDataSource.addLiability(liabilityModel);
      return Right(liabilityModel.toEntity(liability.initialBalance));
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to add liability: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLiability(String id) async {
    try {
      final transactionsOrFailure = await transactionRepository.getTransactions(accountId: id);
      return transactionsOrFailure.fold(
        (failure) => Left(failure),
        (transactions) {
          if (transactions.isNotEmpty) {
            return const Left(ValidationFailure('Cannot delete liability with existing transactions.'));
          }
          localDataSource.deleteLiability(id);
          return const Right(null);
        },
      );
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to delete liability: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Liability>>> getLiabilities() async {
    try {
      final liabilityModels = await localDataSource.getLiabilities();
      final liabilities = <Liability>[];
      for (final model in liabilityModels) {
        final balanceOrFailure = await _calculateBalance(model.id, model.initialBalance);
        balanceOrFailure.fold(
          (failure) => log.warning('Failed to calculate balance for ${model.name}'),
          (balance) => liabilities.add(model.toEntity(balance)),
        );
      }
      return Right(liabilities);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get liabilities: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Liability>> updateLiability(Liability liability) async {
    try {
      final liabilityModel = LiabilityModel.fromEntity(liability);
      await localDataSource.updateLiability(liabilityModel);
      final balanceOrFailure = await _calculateBalance(liability.id, liability.initialBalance);
      return balanceOrFailure.fold(
        (failure) => Left(failure),
        (balance) => Right(liabilityModel.toEntity(balance)),
      );
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to update liability: ${e.toString()}'));
    }
  }

  Future<Either<Failure, double>> _calculateBalance(String liabilityId, double initialBalance) async {
    final transactionsOrFailure = await transactionRepository.getTransactions(accountId: liabilityId);
    return transactionsOrFailure.fold(
      (failure) => Left(failure),
      (transactions) {
        final payments = transactions
            .where((t) => t.type == TransactionType.transfer && t.toAccountId == liabilityId)
            .fold<double>(0, (sum, t) => sum + t.amount);
        return Right(initialBalance - payments);
      },
    );
  }
}
