import 'dart:math';

class SettlementOptimizationEngine {
  /// Optimizes a list of debts (who owes whom how much) to minimize the number of transactions.
  /// Input `balances` represents the net balance for each user.
  /// Positive means the user is owed money. Negative means the user owes money.
  /// Returns a list of optimal transactions: Map of { 'from': String, 'to': String, 'amount': double }
  List<Map<String, dynamic>> optimizeDebts(Map<String, double> balances) {
    List<Map<String, dynamic>> transactions = [];

    // Convert to lists of debtors and creditors
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    balances.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(userId, -balance));
      } else if (balance > 0.01) {
        creditors.add(MapEntry(userId, balance));
      }
    });

    // Sort by largest amounts first for a greedy approach
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    int i = 0; // debtor index
    int j = 0; // creditor index

    while (i < debtors.length && j < creditors.length) {
      String debtorId = debtors[i].key;
      double debtAmount = debtors[i].value;

      String creditorId = creditors[j].key;
      double creditAmount = creditors[j].value;

      double settledAmount = min(debtAmount, creditAmount);

      transactions.add({
        'from': debtorId,
        'to': creditorId,
        'amount': settledAmount,
      });

      debtors[i] = MapEntry(debtorId, debtAmount - settledAmount);
      creditors[j] = MapEntry(creditorId, creditAmount - settledAmount);

      if (debtors[i].value < 0.01) i++;
      if (creditors[j].value < 0.01) j++;
    }

    return transactions;
  }
}
