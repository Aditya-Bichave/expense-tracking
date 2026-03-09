import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/payer_model.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddExpenseWizardState', () {
    test('supports value comparisons', () {
      final date = DateTime(2023, 1, 1);
      final state1 = AddExpenseWizardState(
        expenseDate: date,
        transactionId: '1',
      );
      final state2 = AddExpenseWizardState(
        expenseDate: date,
        transactionId: '1',
      );
      final state3 = AddExpenseWizardState(
        expenseDate: date,
        transactionId: '2',
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('copyWith works correctly', () {
      final date = DateTime(2023, 1, 1);
      final state = AddExpenseWizardState(
        expenseDate: date,
        transactionId: '1',
        errorMessage: 'error',
      );

      expect(
        state.copyWith(amountTotal: 100),
        equals(
          AddExpenseWizardState(
            expenseDate: date,
            transactionId: '1',
            errorMessage: 'error',
            amountTotal: 100,
          ),
        ),
      );

      expect(
        state.copyWith(clearError: true),
        equals(
          AddExpenseWizardState(
            expenseDate: date,
            transactionId: '1',
            errorMessage: null,
          ),
        ),
      );
    });

    test('toApiPayload serializes correctly', () {
      final date = DateTime(2023, 1, 1).toUtc();
      final state = AddExpenseWizardState(
        expenseDate: date,
        transactionId: 't1',
        amountTotal: 100,
        currency: 'USD',
        description: 'Test',
        categoryId: 'c1',
        groupId: 'g1',
        currentUserId: 'u1',
        notes: 'notes',
        receiptCloudUrl: 'url',
        payers: [const PayerModel(userId: 'u1', amountPaid: 100)],
        splits: [
          const SplitModel(
            userId: 'u1',
            shareType: SplitType.EQUAL,
            shareValue: 1,
            computedAmount: 100,
          ),
        ],
      );

      final payload = state.toApiPayload();

      expect(payload['p_group_id'], 'g1');
      expect(payload['p_created_by'], 'u1');
      expect(payload['p_client_generated_id'], 't1');
      expect(payload['p_amount_total'], 100);
      expect(payload['p_currency'], 'USD');
      expect(payload['p_description'], 'Test');
      expect(payload['p_category_id'], 'c1');
      expect(payload['p_expense_date'], date.toIso8601String());
      expect(payload['p_notes'], 'notes');
      expect(payload['p_receipt_url'], 'url');
      expect(payload['p_payers'], isA<List>());
      expect(payload['p_splits'], isA<List>());
    });
  });
}
