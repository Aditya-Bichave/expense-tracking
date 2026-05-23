import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddEditTransactionEvent', () {
    test('InitializeTransaction supports value comparisons', () {
      expect(const InitializeTransaction(), const InitializeTransaction());
    });

    test('TransactionTypeChanged supports value comparisons', () {
      expect(
        const TransactionTypeChanged(TransactionType.expense),
        const TransactionTypeChanged(TransactionType.expense),
      );
    });

    test('SaveTransactionRequested supports value comparisons', () {
      final category = Category(
        id: '1',
        name: 'Test',
        type: CategoryType.expense,
        iconName: 'icon',
        colorHex: 'color',
        isCustom: false,
      );
      expect(
        SaveTransactionRequested(
          title: 't',
          amount: 10,
          date: DateTime(2023),
          category: category,
          accountId: '1',
        ),
        SaveTransactionRequested(
          title: 't',
          amount: 10,
          date: DateTime(2023),
          category: category,
          accountId: '1',
        ),
      );
    });

    test('AcceptCategorySuggestion supports value comparisons', () {
      final category = Category(
        id: '1',
        name: 'Test',
        type: CategoryType.expense,
        iconName: 'icon',
        colorHex: 'color',
        isCustom: false,
      );
      expect(
        AcceptCategorySuggestion(category),
        AcceptCategorySuggestion(category),
      );
    });

    test('RejectCategorySuggestion supports value comparisons', () {
      expect(
        const RejectCategorySuggestion(),
        const RejectCategorySuggestion(),
      );
    });

    test('CreateCustomCategoryRequested supports value comparisons', () {
      expect(
        CreateCustomCategoryRequested(
          title: 't',
          amount: 10,
          date: DateTime(2023),
          accountId: '1',
        ),
        CreateCustomCategoryRequested(
          title: 't',
          amount: 10,
          date: DateTime(2023),
          accountId: '1',
        ),
      );
    });

    test('CategoryCreated supports value comparisons', () {
      final category = Category(
        id: '1',
        name: 'Test',
        type: CategoryType.expense,
        iconName: 'icon',
        colorHex: 'color',
        isCustom: false,
      );
      expect(CategoryCreated(category), CategoryCreated(category));
    });

    test('ClearMessages supports value comparisons', () {
      expect(const ClearMessages(), const ClearMessages());
    });
  });
}
