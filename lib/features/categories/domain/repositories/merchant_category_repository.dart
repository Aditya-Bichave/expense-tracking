import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';

abstract class MerchantCategoryRepository {
  /// Gets the default category ID for a given merchant identifier.
  /// Returns null if no mapping exists.
  Future<Either<Failure, String?>> getDefaultCategoryId(
      String merchantIdentifier);
}
