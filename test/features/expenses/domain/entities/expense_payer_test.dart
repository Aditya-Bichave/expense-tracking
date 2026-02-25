import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpensePayer', () {
    test('supports value equality', () {
      const payer1 = ExpensePayer(userId: 'u1', amountPaid: 50.0);
      const payer2 = ExpensePayer(userId: 'u1', amountPaid: 50.0);

      expect(payer1, equals(payer2));
    });
  });
}
