import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_state.dart';

void main() {
  test('RecordSettlementState works correctly', () {
    final state1 = RecordSettlementState(amount: 100.0, note: 'note');
    final state2 = RecordSettlementState(amount: 100.0, note: 'note');
    final state3 = RecordSettlementState(amount: 50.0, note: 'note');
    expect(state1, equals(state2));
    expect(state1, isNot(equals(state3)));
  });
}
