import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_sort_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApplySortCallback extends Mock {
  void call(TransactionSortBy sortBy, SortDirection sortDirection);
}

void main() {
  late MockApplySortCallback mockOnApplySort;

  setUp(() {
    mockOnApplySort = MockApplySortCallback();
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required TransactionSortBy currentSortBy,
    required SortDirection currentSortDirection,
  }) async {
    // Wrap in MaterialApp to provide context for Navigator.pop
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionSortSheet(
            currentSortBy: currentSortBy,
            currentSortDirection: currentSortDirection,
            onApplySort: mockOnApplySort.call,
          ),
        ),
      ),
    );
  }

  group('TransactionSortSheet', () {
    testWidgets('renders all options and highlights the current one',
        (tester) async {
      await pumpSheet(
        tester,
        currentSortBy: TransactionSortBy.amount,
        currentSortDirection: SortDirection.descending,
      );

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);

      final amountTile =
          tester.widget<RadioListTile<TransactionSortBy>>(find.ancestor(
        of: find.text('Amount'),
        matching: find.byType(RadioListTile<TransactionSortBy>),
      ));
      expect(amountTile.groupValue, TransactionSortBy.amount);
      expect(find.byIcon(Icons.arrow_downward_rounded),
          findsNWidgets(2)); // Date & Amount
    });

    testWidgets(
        'tapping a new sort option calls onApplySort with new option and default direction',
        (tester) async {
      when(() => mockOnApplySort.call(any(), any())).thenAnswer((_) {});
      await pumpSheet(
        tester,
        currentSortBy: TransactionSortBy.date,
        currentSortDirection: SortDirection.descending,
      );

      await tester.tap(find.text('Title'));

      verify(() => mockOnApplySort.call(
          TransactionSortBy.title, SortDirection.ascending)).called(1);
    });

    testWidgets(
        'tapping the current sort option calls onApplySort with toggled direction',
        (tester) async {
      when(() => mockOnApplySort.call(any(), any())).thenAnswer((_) {});
      await pumpSheet(
        tester,
        currentSortBy: TransactionSortBy.date,
        currentSortDirection: SortDirection.descending,
      );

      await tester.tap(find.text('Date'));

      verify(() => mockOnApplySort.call(
          TransactionSortBy.date, SortDirection.ascending)).called(1);
    });
  });
}
