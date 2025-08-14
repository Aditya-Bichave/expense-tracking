import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not crash when AccountListBloc is absent', (tester) async {
    bool callbackInvoked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionFilterDialog(
          onApplyFilter: (a, b, c, d, e) {},
          onClearFilter: () {},
          availableCategories: const [],
          onLoadAccounts: () => callbackInvoked = true,
          accountSelectorBuilder: (selected, onChanged) => const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFilterDialog), findsOneWidget);
    expect(callbackInvoked, isTrue);
  });
}
