import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/categorization_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  void onUserCategorized(TransactionEntity tx, Category category);
  void onChangeCategoryRequest(TransactionEntity tx);
}

void main() {
  late MockCallbacks mockCallbacks;
  final mockCategory =
      Category(id: 'cat1', name: 'Suggested', iconName: 'test', color: 0);
  final mockTransaction = TransactionEntity(
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

  Widget buildTestWidget(TransactionEntity transaction) {
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
          mockTransaction.copyWith(status: CategorizationStatus.needsReview);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      expect(find.text('Suggest: Suggested'), findsOneWidget);
      expect(find.byKey(const ValueKey('button_categorization_confirm')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('button_categorization_change')),
          findsOneWidget);
    });

    testWidgets('renders "uncategorized" state and button correctly',
        (tester) async {
      final tx =
          mockTransaction.copyWith(status: CategorizationStatus.uncategorized);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      expect(find.byKey(const ValueKey('button_categorization_categorize')),
          findsOneWidget);
    });

    testWidgets('renders "categorized" state correctly', (tester) async {
      final tx =
          mockTransaction.copyWith(status: CategorizationStatus.categorized);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      expect(find.text('Suggested'), findsOneWidget);
    });

    testWidgets('"Confirm" button calls onUserCategorized', (tester) async {
      when(() => mockCallbacks.onUserCategorized(any(), any()))
          .thenAnswer((_) {});
      final tx =
          mockTransaction.copyWith(status: CategorizationStatus.needsReview);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      await tester
          .tap(find.byKey(const ValueKey('button_categorization_confirm')));

      verify(() => mockCallbacks.onUserCategorized(tx, mockCategory)).called(1);
    });

    testWidgets(
        '"Change" and "Categorize" buttons call onChangeCategoryRequest',
        (tester) async {
      when(() => mockCallbacks.onChangeCategoryRequest(any()))
          .thenAnswer((_) {});

      // Test "Change" button
      final txReview =
          mockTransaction.copyWith(status: CategorizationStatus.needsReview);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(txReview));
      await tester
          .tap(find.byKey(const ValueKey('button_categorization_change')));
      verify(() => mockCallbacks.onChangeCategoryRequest(txReview)).called(1);

      // Test "Categorize" button
      final txUncat =
          mockTransaction.copyWith(status: CategorizationStatus.uncategorized);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(txUncat));
      await tester
          .tap(find.byKey(const ValueKey('button_categorization_categorize')));
      verify(() => mockCallbacks.onChangeCategoryRequest(txUncat)).called(1);
    });

    testWidgets('Tapping categorized text calls onChangeCategoryRequest',
        (tester) async {
      when(() => mockCallbacks.onChangeCategoryRequest(any()))
          .thenAnswer((_) {});
      final tx =
          mockTransaction.copyWith(status: CategorizationStatus.categorized);
      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(tx));

      await tester.tap(find
          .byKey(const ValueKey('inkwell_categorization_change_categorized')));

      verify(() => mockCallbacks.onChangeCategoryRequest(tx)).called(1);
    });
  });
}
