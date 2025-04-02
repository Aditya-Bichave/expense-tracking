import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

class FinancialOverview extends Equatable {
  final double totalIncome; // For selected period
  final double totalExpenses; // For selected period
  final double netFlow; // income - expenses
  final double overallBalance; // Sum of all account current balances
  final List<AssetAccount> accounts; // List of full account objects
  final Map<String, double>
      accountBalances; // Map<AccountName, Balance> for Pie Chart

  const FinancialOverview({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.overallBalance,
    required this.accounts,
    required this.accountBalances, // Added map
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        netFlow,
        overallBalance,
        accounts,
        accountBalances, // Added to props
      ];

  // --- REMOVED INCORRECT GETTER ---
  // get totalBalance => null; // <-- THIS WAS A BUG, use 'overallBalance' field
}
