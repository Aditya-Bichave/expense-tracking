import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class GetIncomesUseCase implements UseCase<List<Income>, GetIncomesParams> {
  final IncomeRepository repository;

  GetIncomesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Income>>> call(GetIncomesParams params) async {
    final result = await repository.getIncomes(
      startDate: params.startDate,
      endDate: params.endDate,
      categoryId: params.category, // Assuming 'category' in params maps to 'categoryId' in repo
      accountId: params.accountId,
    );

    return result.fold(
      (failure) => Left(failure),
      (models) {
        // Map List<IncomeModel> to List<Income>
        // Note: toEntity might require external category lookup but for now let's use what's available.
        // Wait, toEntity returns Income with category=null.
        // Ideally the repository or datasource should handle mapping and returning full entities,
        // or the use case needs to fetch categories to populate them.
        // Given the code I saw in IncomeModel, toEntity sets category to null.
        // This might be a limitation of the current architecture.
        // I will just map them for now as is.
        final entities = models.map((m) => m.toEntity()).toList();
        return Right(entities);
      },
    );
  }
}

class GetIncomesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId;

  const GetIncomesParams(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}
