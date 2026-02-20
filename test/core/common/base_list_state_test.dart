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
  test('BaseListState filtersApplied returns correct boolean', () {
    const stateEmpty = TestListState(items: []);
    expect(stateEmpty.filtersApplied, isFalse);

    // Remove const here because DateTime constructor is not const
    final stateWithDate = TestListState(
      items: [],
      filterStartDate: DateTime(2023),
    );
    expect(stateWithDate.filtersApplied, isTrue);

    const stateWithCategory = TestListState(items: [], filterCategory: 'food');
    expect(stateWithCategory.filtersApplied, isTrue);
  });

  test('BaseListState equality works', () {
    const state1 = TestListState(items: ['a']);
    const state2 = TestListState(items: ['a']);
    const state3 = TestListState(items: ['b']);

    expect(state1, equals(state2));
    expect(state1, isNot(equals(state3)));
  });
}
