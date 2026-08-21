import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrashBin events and states props', () {
    test('LoadTrash props', () {
      expect(LoadTrash().props, isEmpty);
    });

    test('RestoreItem props', () {
      const event = RestoreItem(id: '1', type: TrashItemType.expense);
      expect(event.props, ['1', TrashItemType.expense]);
    });

    test('PurgeItem props', () {
      const event = PurgeItem(id: '2', type: TrashItemType.income);
      expect(event.props, ['2', TrashItemType.income]);
    });

    test('TrashBinInitial props', () {
      expect(TrashBinInitial().props, isEmpty);
    });

    test('TrashBinLoading props', () {
      expect(TrashBinLoading().props, isEmpty);
    });

    test('TrashBinEmpty props', () {
      expect(TrashBinEmpty().props, isEmpty);
    });

    test('TrashBinError props', () {
      const state = TrashBinError('err');
      expect(state.props, ['err']);
    });
  });
}
