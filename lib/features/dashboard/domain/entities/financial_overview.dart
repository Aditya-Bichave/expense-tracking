import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

class FinancialOverview extends Equatable {
  final double totalIncome; // For selected period
  final double totalExpenses; // For selected period
  final double netFlow; // income - expenses
  final double overallBalance; // Sum of all account current balances
  final List<AssetAccount> accounts; // List of full account objects
  // Map<AccountName, Balance> - Ensure only positive balances are included for the pie chart here? Or filter later.
  final Map<String, double> accountBalances;

  const FinancialOverview({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.overallBalance,
    required this.accounts,
    required this.accountBalances,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        netFlow,
        overallBalance,
        accounts,
        accountBalances,
      ];
}
