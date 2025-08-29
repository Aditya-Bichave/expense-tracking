import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockCallbacks extends Mock {
  void onApplyFilter(DateTime? startDate, DateTime? endDate,
      TransactionType? transactionType, String? accountId, String? categoryId);
  void onClearFilter();
}

void main() {
  late MockAccountListBloc mockAccountListBloc;
  late MockCallbacks mockCallbacks;

  setUp(() {
    mockAccountListBloc = MockAccountListBloc();
    mockCallbacks = MockCallbacks();
    when(() => mockAccountListBloc.state)
        .thenReturn(const AccountListLoaded(accounts: []));
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    DateTime? startDate,
    TransactionType? type,
  }) async {
    // The dialog needs a navigator to be shown and dismissed.
    // We wrap it in a MaterialApp and a Scaffold with a button to launch it.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AccountListBloc>.value(
            value: mockAccountListBloc,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  child: const Text('Show Dialog'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (dialogContext) => TransactionFilterDialog(
                      initialStartDate: startDate,
                      initialTransactionType: type,
                      availableCategories: const [],
                      onApplyFilter: mockCallbacks.onApplyFilter,
                      onClearFilter: mockCallbacks.onClearFilter,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
  }

  group('TransactionFilterDialog', () {
    testWidgets('initializes with initial values', (tester) async {
      final date = DateTime(2023);
      await pumpDialog(tester, startDate: date, type: TransactionType.expense);

      expect(find.byType(TransactionFilterDialog), findsOneWidget);
      expect(find.text(DateFormatter.formatDate(date)), findsOneWidget);
      expect(find.text('Expenses Only'), findsOneWidget);
    });

    testWidgets('calls onApplyFilter with updated values when Apply is tapped',
        (tester) async {
      when(() => mockCallbacks.onApplyFilter(any(), any(), any(), any(), any()))
          .thenAnswer((_) {});
      await pumpDialog(tester);

      // Change a value
      await tester.tap(find.text('All Types'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income Only').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_filterDialog_apply')));

      verify(() => mockCallbacks.onApplyFilter(
            null,
            null,
            TransactionType.income,
            null,
            null,
          )).called(1);
    });

    testWidgets('calls onClearFilter when Clear All is tapped', (tester) async {
      when(() => mockCallbacks.onClearFilter()).thenAnswer((_) {});
      await pumpDialog(tester);

      await tester.tap(find.byKey(const ValueKey('button_filterDialog_clear')));

      verify(() => mockCallbacks.onClearFilter()).called(1);
    });

    testWidgets('dialog is dismissed after applying filters', (tester) async {
      when(() => mockCallbacks.onApplyFilter(any(), any(), any(), any(), any()))
          .thenAnswer((_) {});
      await pumpDialog(tester);
      expect(find.byType(TransactionFilterDialog), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('button_filterDialog_apply')));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFilterDialog), findsNothing);
    });
  });
}
