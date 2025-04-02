import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

class GetFinancialOverviewUseCase
    implements UseCase<FinancialOverview, GetFinancialOverviewParams> {
  final AssetAccountRepository accountRepository;
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;

  GetFinancialOverviewUseCase({
    required this.accountRepository,
    required this.incomeRepository,
    required this.expenseRepository,
  });

  @override
  Future<Either<Failure, FinancialOverview>> call(
      GetFinancialOverviewParams params) async {
    try {
      // 1. Get all accounts (with calculated balances)
      final accountsEither = await accountRepository.getAssetAccounts();
      // Use flatMap or handle error propagation more explicitly if needed
      final accounts = accountsEither.getOrElse(() => <AssetAccount>[]);
      if (accountsEither.isLeft()) {
        return Left(accountsEither.fold(
            (l) => l, (_) => CacheFailure("Error fetching accounts")));
      }

      // 2. Calculate overall balance
      final double overallBalance =
          accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);

      // 3. Create the map for the pie chart <AccountName, Balance>
      final Map<String, double> accountBalancesMap = {
        for (var acc in accounts) acc.name: acc.currentBalance
      };

      // 4. Get total income/expenses for the period (using date filters if provided)
      final totalIncomeEither = await incomeRepository.getTotalIncomeForAccount(
        '', // Pass empty accountId to get all
        startDate: params.startDate,
        endDate: params.endDate,
      );
      final totalExpensesEither =
          await expenseRepository.getTotalExpensesForAccount(
        '', // Pass empty accountId to get all
        startDate: params.startDate,
        endDate: params.endDate,
      );

      // Consider propagating failures from income/expense fetches if needed,
      // otherwise defaulting to 0.0 is reasonable for a summary.
      final totalIncome = totalIncomeEither.fold((l) {
        print("Failed to get total income: $l"); // Log error
        return 0.0; // Default on failure
      }, (r) => r);
      final totalExpenses = totalExpensesEither.fold((l) {
        print("Failed to get total expense: $l"); // Log error
        return 0.0; // Default on failure
      }, (r) => r);
      final netFlow = totalIncome - totalExpenses;

      // 5. Construct the overview object with the new map
      final overview = FinancialOverview(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netFlow: netFlow,
        overallBalance: overallBalance,
        accounts: accounts, // Keep the original list if needed elsewhere
        accountBalances: accountBalancesMap, // Pass the created map
      );

      return Right(overview);
    } catch (e, s) {
      // Catch specific exceptions if possible
      // Catch any unexpected errors during the multi-step process
      print("Unexpected error in GetFinancialOverviewUseCase: $e\n$s");
      return Left(CacheFailure(
          'Failed to generate financial overview: ${e.toString()}'));
    }
  }
}

class GetFinancialOverviewParams extends Equatable {
  final DateTime? startDate; // Optional filter for income/expense totals
  final DateTime? endDate;

  const GetFinancialOverviewParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
