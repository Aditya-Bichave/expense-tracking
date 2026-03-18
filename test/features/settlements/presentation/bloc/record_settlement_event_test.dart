import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_event.dart';

void main() {
  test('RecordSettlementEvent works correctly', () {
    final ev1 = AmountChanged(100.0);
    final ev2 = AmountChanged(100.0);
    final ev3 = AmountChanged(50.0);
    expect(ev1, equals(ev2));
    expect(ev1, isNot(equals(ev3)));
  });
}
