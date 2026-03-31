import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/add_expense/domain/models/payer_model.dart';

void main() {
  group('PayerModel Test', () {
    test('toJson returns correctly formatted map', () {
      const payer = PayerModel(userId: 'user_123', amountPaid: 50.0);
      final json = payer.toJson();

      expect(json, {'user_id': 'user_123', 'amount_paid': 50.0});
    });

    test('props contain correct values for equatable', () {
      const payer = PayerModel(userId: 'user_123', amountPaid: 50.0);
      expect(payer.props, ['user_123', 50.0]);
    });

    test('two instances with same values are equal', () {
      const payer1 = PayerModel(userId: 'user_123', amountPaid: 50.0);
      const payer2 = PayerModel(userId: 'user_123', amountPaid: 50.0);
      expect(payer1, payer2);
    });
  });
}
