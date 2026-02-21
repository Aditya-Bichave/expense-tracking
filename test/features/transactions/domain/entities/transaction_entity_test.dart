import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';

void main() {
  const tCategory = Category.uncategorized;
  final tDate = DateTime(2023, 1, 1);
  const tId = '1';
  const tTitle = 'Test Transaction';
  const tAmount = 100.0;
  const tAccountId = 'acc1';
  const tStatus = CategorizationStatus.categorized;
  const tConfidence = 0.9;
  const tMerchantId = 'merch1';
  const tNotes = 'Test notes';

  final tTransaction = TransactionEntity(
    id: tId,
    type: TransactionType.expense,
    title: tTitle,
    amount: tAmount,
    date: tDate,
    category: tCategory,
    accountId: tAccountId,
    notes: tNotes,
    status: tStatus,
    confidenceScore: tConfidence,
    isRecurring: true,
    merchantId: tMerchantId,
  );

  group('TransactionEntity', () {
    test('props should contain all fields', () {
      expect(tTransaction.props, [
        tId,
        TransactionType.expense,
        tTitle,
        tAmount,
        tDate,
        tCategory,
        tAccountId,
        tNotes,
        tStatus,
        tConfidence,
        true,
        tMerchantId,
      ]);
    });

    test('supports value equality', () {
      final tTransaction2 = TransactionEntity(
        id: tId,
        type: TransactionType.expense,
        title: tTitle,
        amount: tAmount,
        date: tDate,
        category: tCategory,
        accountId: tAccountId,
        notes: tNotes,
        status: tStatus,
        confidenceScore: tConfidence,
        isRecurring: true,
        merchantId: tMerchantId,
      );
      expect(tTransaction, equals(tTransaction2));
    });

    group('fromExpense', () {
      test('should create a valid TransactionEntity from Expense', () {
        final tExpense = Expense(
          id: tId,
          title: tTitle,
          amount: tAmount,
          date: tDate,
          category: tCategory,
          accountId: tAccountId,
          status: tStatus,
          confidenceScore: tConfidence,
          isRecurring: true,
          merchantId: tMerchantId,
        );

        final result = TransactionEntity.fromExpense(tExpense);

        expect(result.id, tExpense.id);
        expect(result.type, TransactionType.expense);
        expect(result.title, tExpense.title);
        expect(result.amount, tExpense.amount);
        expect(result.date, tExpense.date);
        expect(result.category, tExpense.category);
        expect(result.accountId, tExpense.accountId);
        expect(result.notes, null); // Expenses don't have notes
        expect(result.status, tExpense.status);
        expect(result.confidenceScore, tExpense.confidenceScore);
        expect(result.isRecurring, tExpense.isRecurring);
        expect(result.merchantId, tExpense.merchantId);
        expect(result.expense, tExpense);
        expect(result.income, null);
      });
    });

    group('fromIncome', () {
      test('should create a valid TransactionEntity from Income', () {
        final tIncome = Income(
          id: tId,
          title: tTitle,
          amount: tAmount,
          date: tDate,
          category: tCategory,
          accountId: tAccountId,
          notes: tNotes,
          status: tStatus,
          confidenceScore: tConfidence,
          isRecurring: true,
          merchantId: tMerchantId,
        );

        final result = TransactionEntity.fromIncome(tIncome);

        expect(result.id, tIncome.id);
        expect(result.type, TransactionType.income);
        expect(result.title, tIncome.title);
        expect(result.amount, tIncome.amount);
        expect(result.date, tIncome.date);
        expect(result.category, tIncome.category);
        expect(result.accountId, tIncome.accountId);
        expect(result.notes, tIncome.notes);
        expect(result.status, tIncome.status);
        expect(result.confidenceScore, tIncome.confidenceScore);
        expect(result.isRecurring, tIncome.isRecurring);
        expect(result.merchantId, tIncome.merchantId);
        expect(result.expense, null);
        expect(result.income, tIncome);
      });
    });

    group('copyWith', () {
      test('should return a copy with updated fields', () {
        final result = tTransaction.copyWith(title: 'New Title', amount: 200.0);

        expect(result.title, 'New Title');
        expect(result.amount, 200.0);
        expect(result.id, tTransaction.id); // Original field
      });

      test('should return the same object if no fields are provided', () {
        final result = tTransaction.copyWith();
        expect(result, tTransaction);
      });
    });
  });
}
