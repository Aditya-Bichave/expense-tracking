import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordSettlementState', () {
    test('supports value comparisons', () {
      expect(const RecordSettlementState(), const RecordSettlementState());
    });

    test('copyWith works correctly', () {
      final state = const RecordSettlementState().copyWith(
        amount: 100,
        note: 'Test note',
        status: FormStatus.success,
        waitingForUpiConfirmation: true,
      );

      expect(state.amount, 100);
      expect(state.note, 'Test note');
      expect(state.status, FormStatus.success);
      expect(state.waitingForUpiConfirmation, true);
    });
  });
}
