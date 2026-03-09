import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringListEvent', () {
    test('LoadRecurringRules supports value comparisons', () {
      expect(LoadRecurringRules(), equals(LoadRecurringRules()));
    });

    test('PauseResumeRule supports value comparisons', () {
      expect(const PauseResumeRule('1'), equals(const PauseResumeRule('1')));
      expect(
        const PauseResumeRule('1'),
        isNot(equals(const PauseResumeRule('2'))),
      );
    });

    test('DeleteRule supports value comparisons', () {
      expect(const DeleteRule('1'), equals(const DeleteRule('1')));
      expect(const DeleteRule('1'), isNot(equals(const DeleteRule('2'))));
    });

    test('ResetState supports value comparisons', () {
      expect(const ResetState(), equals(const ResetState()));
    });
  });
}
