import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/merchant_category_data_source.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:expense_tracker/core/utils/logger.dart';

class MerchantCategoryRepositoryImpl implements MerchantCategoryRepository {
  final MerchantCategoryDataSource dataSource;

  MerchantCategoryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, String?>> getDefaultCategoryId(
    String merchantIdentifier,
  ) async {
    log.fine(
      "[MerchantCategoryRepo] getDefaultCategoryId called for '$merchantIdentifier'.",
    );
    try {
      final categoryId = await dataSource.getDefaultCategoryId(
        merchantIdentifier,
      );
      log.fine("[MerchantCategoryRepo] DataSource returned: $categoryId");
      return Right(categoryId);
    } on CacheFailure catch (e) {
      log.warning(
        "[MerchantCategoryRepo] CacheFailure during getDefaultCategoryId: ${e.message}",
      );
      return Left(e); // Propagate specific failure
    } catch (e, s) {
      log.severe(
        "[MerchantCategoryRepo] Unexpected error in getDefaultCategoryId$e$s",
      );
      return Left(
        CacheFailure("Failed to lookup merchant category: ${e.toString()}"),
      );
    }
  }
}
