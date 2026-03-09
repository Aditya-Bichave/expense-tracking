import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddExpenseWizardEvent', () {
    test('WizardStarted supports value comparisons', () {
      expect(const WizardStarted(), equals(const WizardStarted()));
    });

    test('AmountChanged supports value comparisons', () {
      expect(const AmountChanged(100), equals(const AmountChanged(100)));
      expect(const AmountChanged(100), isNot(equals(const AmountChanged(200))));
    });

    test('DescriptionChanged supports value comparisons', () {
      expect(
        const DescriptionChanged('Food'),
        equals(const DescriptionChanged('Food')),
      );
      expect(
        const DescriptionChanged('Food'),
        isNot(equals(const DescriptionChanged('Drinks'))),
      );
    });

    test('CategorySelected supports value comparisons', () {
      const cat1 = Category(
        id: '1',
        name: 'Food',
        iconName: 'food',
        colorHex: '#00',
        type: CategoryType.expense,
        isCustom: false,
      );
      const cat2 = Category(
        id: '2',
        name: 'Drinks',
        iconName: 'drinks',
        colorHex: '#00',
        type: CategoryType.expense,
        isCustom: false,
      );
      expect(
        const CategorySelected(cat1),
        equals(const CategorySelected(cat1)),
      );
      expect(
        const CategorySelected(cat1),
        isNot(equals(const CategorySelected(cat2))),
      );
    });

    test('GroupSelected supports value comparisons', () {
      final group1 = GroupEntity(
        id: '1',
        name: 'Group 1',
        type: GroupType.trip,
        currency: 'USD',
        createdBy: '1',
        createdAt: DateTime(2023),
        updatedAt: DateTime(2023),
      );
      final group2 = GroupEntity(
        id: '2',
        name: 'Group 2',
        type: GroupType.trip,
        currency: 'USD',
        createdBy: '1',
        createdAt: DateTime(2023),
        updatedAt: DateTime(2023),
      );
      expect(GroupSelected(group1), equals(GroupSelected(group1)));
      expect(GroupSelected(group1), isNot(equals(GroupSelected(group2))));
      expect(const GroupSelected(null), equals(const GroupSelected(null)));
    });

    test('DateChanged supports value comparisons', () {
      final d1 = DateTime(2023, 1, 1);
      final d2 = DateTime(2023, 1, 2);
      expect(DateChanged(d1), equals(DateChanged(d1)));
      expect(DateChanged(d1), isNot(equals(DateChanged(d2))));
    });

    test('NotesChanged supports value comparisons', () {
      expect(
        const NotesChanged('Note 1'),
        equals(const NotesChanged('Note 1')),
      );
      expect(
        const NotesChanged('Note 1'),
        isNot(equals(const NotesChanged('Note 2'))),
      );
    });

    test('ReceiptSelected supports value comparisons', () {
      expect(
        const ReceiptSelected('path1'),
        equals(const ReceiptSelected('path1')),
      );
      expect(
        const ReceiptSelected('path1'),
        isNot(equals(const ReceiptSelected('path2'))),
      );
    });

    test('SplitModeChanged supports value comparisons', () {
      expect(
        const SplitModeChanged(SplitMode.equal),
        equals(const SplitModeChanged(SplitMode.equal)),
      );
      expect(
        const SplitModeChanged(SplitMode.equal),
        isNot(equals(const SplitModeChanged(SplitMode.exact))),
      );
    });

    test('SplitValueChanged supports value comparisons', () {
      expect(
        const SplitValueChanged('u1', 10),
        equals(const SplitValueChanged('u1', 10)),
      );
      expect(
        const SplitValueChanged('u1', 10),
        isNot(equals(const SplitValueChanged('u2', 10))),
      );
      expect(
        const SplitValueChanged('u1', 10),
        isNot(equals(const SplitValueChanged('u1', 20))),
      );
    });

    test('SinglePayerSelected supports value comparisons', () {
      expect(
        const SinglePayerSelected('u1'),
        equals(const SinglePayerSelected('u1')),
      );
      expect(
        const SinglePayerSelected('u1'),
        isNot(equals(const SinglePayerSelected('u2'))),
      );
    });

    test('PayerChanged supports value comparisons', () {
      expect(
        const PayerChanged('u1', 10),
        equals(const PayerChanged('u1', 10)),
      );
      expect(
        const PayerChanged('u1', 10),
        isNot(equals(const PayerChanged('u2', 10))),
      );
      expect(
        const PayerChanged('u1', 10),
        isNot(equals(const PayerChanged('u1', 20))),
      );
    });

    test('SubmitExpense supports value comparisons', () {
      expect(const SubmitExpense(), equals(const SubmitExpense()));
    });

    test('ClearWizardMessage supports value comparisons', () {
      expect(const ClearWizardMessage(), equals(const ClearWizardMessage()));
    });
  });
}
