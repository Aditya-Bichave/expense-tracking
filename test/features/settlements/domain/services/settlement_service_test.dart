import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settlements/domain/services/settlement_service.dart';

void main() {
  group('SettlementOptimizationEngine', () {
    late SettlementOptimizationEngine engine;

    setUp(() {
      engine = SettlementOptimizationEngine();
    });

    test('optimizes circular debts correctly', () {
      Map<String, double> balances = {'A': 0.0, 'B': 0.0, 'C': 0.0};

      final transactions = engine.optimizeDebts(balances);
      expect(transactions.length, 0);
    });

    test('optimizes chain of debts to single transaction', () {
      Map<String, double> balances = {'A': -10.0, 'B': 0.0, 'C': 10.0};

      final transactions = engine.optimizeDebts(balances);
      expect(transactions.length, 1);
      expect(transactions[0]['from'], 'A');
      expect(transactions[0]['to'], 'C');
      expect(transactions[0]['amount'], 10.0);
    });

    test('optimizes multiple debtors and creditors greedily', () {
      Map<String, double> balances = {
        'A': -50.0, // owes 50
        'B': -20.0, // owes 20
        'C': 40.0, // is owed 40
        'D': 30.0, // is owed 30
      };

      final transactions = engine.optimizeDebts(balances);

      expect(transactions.length, 3);

      double aPaid = transactions
          .where((t) => t['from'] == 'A')
          .fold(0.0, (sum, t) => sum + t['amount']);
      expect(aPaid, 50.0);

      double bPaid = transactions
          .where((t) => t['from'] == 'B')
          .fold(0.0, (sum, t) => sum + t['amount']);
      expect(bPaid, 20.0);

      double cReceived = transactions
          .where((t) => t['to'] == 'C')
          .fold(0.0, (sum, t) => sum + t['amount']);
      expect(cReceived, 40.0);

      double dReceived = transactions
          .where((t) => t['to'] == 'D')
          .fold(0.0, (sum, t) => sum + t['amount']);
      expect(dReceived, 30.0);
    });
  });
}
