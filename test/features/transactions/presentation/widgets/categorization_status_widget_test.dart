import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/categorization_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  void onUserCategorized(Transaction tx, Category category);
  void onChangeCategoryRequest(Transaction tx);
}

void main() {
  late MockCallbacks mockCallbacks;
  final mockCategory = Category(
    id: 'cat1',
    name: 'Suggested',
    iconName: 'test',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: true,
  );
  final mockTransaction = Transaction(
    id: '1',
    title: 'Test',
    amount: 10,
    date: DateTime.now(),
    type: TransactionType.expense,
    category: mockCategory,
  );

  setUp(() {
    mockCallbacks = MockCallbacks();
  });

  Widget buildTestWidget(Transaction transaction) {
    return CategorizationStatusWidget(
      transaction: transaction,
      onUserCategorized: mockCallbacks.onUserCategorized,
      onChangeCategoryRequest: mockCallbacks.onChangeCategoryRequest,
    );
  }

  group('CategorizationStatusWidget', () {
    testWidgets('renders "needsReview" state and buttons correctly',
        (tester) async {
      final tx =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      expect(find.text('Suggested'), findsOneWidget);
    });

    testWidgets('renders "uncategorized" state and button correctly',
        (tester) async {
      final tx =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      expect(find.text('Suggested'), findsOneWidget);
    });

    testWidgets('renders "categorized" state correctly', (tester) async {
      final tx =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      expect(find.text('Suggested'), findsOneWidget);
    });

    testWidgets('"Confirm" button calls onUserCategorized', (tester) async {
      when(() => mockCallbacks.onUserCategorized(any(), any()))
          .thenAnswer((_) {});
      final tx =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      await tester
          .tap(find.byKey(const ValueKey('inkwell_categorization_change_categorized')));

      verify(() => mockCallbacks.onChangeCategoryRequest(tx)).called(1);
    });

    testWidgets(
        '"Change" and "Categorize" buttons call onChangeCategoryRequest',
        (tester) async {
      when(() => mockCallbacks.onChangeCategoryRequest(any()))
          .thenAnswer((_) {});

      // Test "Change" button
      final txReview =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(txReview));
      await tester
          .tap(find.byKey(const ValueKey('inkwell_categorization_change_categorized')));
      verify(() => mockCallbacks.onChangeCategoryRequest(txReview)).called(1);

      // Test "Categorize" button
      final txUncat =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(txUncat));
      await tester
          .tap(find.byKey(const ValueKey('inkwell_categorization_change_categorized')));
      verify(() => mockCallbacks.onChangeCategoryRequest(txUncat)).called(1);
    });

    testWidgets('Tapping categorized text calls onChangeCategoryRequest',
        (tester) async {
      when(() => mockCallbacks.onChangeCategoryRequest(any()))
          .thenAnswer((_) {});
      final tx =
          mockTransaction.copyWith();
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      await tester.tap(find
          .byKey(const ValueKey('inkwell_categorization_change_categorized')));

      verify(() => mockCallbacks.onChangeCategoryRequest(tx)).called(1);
    });
  });
}
