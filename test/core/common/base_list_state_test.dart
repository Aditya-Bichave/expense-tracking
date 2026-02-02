
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

class TestListState extends BaseListState<String> {
  const TestListState({
    required super.items,
    super.filterStartDate,
    super.filterEndDate,
    super.filterCategory,
    super.filterAccountId,
  });
}

void main() {
  group('BaseListState', () {
    test('filtersApplied returns true when any filter is set', () {
      expect(const TestListState(items: []).filtersApplied, false);
      expect(
          TestListState(items: [], filterStartDate: DateTime.now())
              .filtersApplied,
          true);
      expect(
          TestListState(items: [], filterEndDate: DateTime.now())
              .filtersApplied,
          true);
      expect(const TestListState(items: [], filterCategory: 'Cat').filtersApplied,
          true);
      expect(const TestListState(items: [], filterAccountId: 'Acc').filtersApplied,
          true);
    });

    test('props contains all fields', () {
      final now = DateTime.now();
      final state = TestListState(
        items: const ['Item'],
        filterStartDate: now,
        filterEndDate: now,
        filterCategory: 'Cat',
        filterAccountId: 'Acc',
      );

      expect(state.props, [
        ['Item'],
        now,
        now,
        'Cat',
        'Acc',
      ]);
    });
  });
}
