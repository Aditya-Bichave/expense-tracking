import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TransactionListItem uses theme spacing', (tester) async {
    const spacingSmall = 10.0;
    const spacingMedium = 20.0;
    final theme = ThemeData(
      extensions: [
        AppModeTheme(
          modeId: 'test',
          layoutDensity: LayoutDensity.comfortable,
          cardStyle: CardStyle.flat,
          assets: const ThemeAssetPaths(),
          preferDataTableForLists: false,
          primaryAnimationDuration: Duration.zero,
          listEntranceAnimation: ListEntranceAnimation.none,
          spacingSmall: spacingSmall,
          spacingMedium: spacingMedium,
          spacingLarge: 30.0,
        ),
      ],
    );

    final category = Category(
      id: 'c1',
      name: 'Food',
      iconName: 'restaurant',
      colorHex: '#ffffff',
      type: CategoryType.expense,
      isCustom: false,
    );
    final expense = Expense(
      id: 'e1',
      title: 'Coffee',
      amount: 3.0,
      date: DateTime(2024, 1, 1),
      accountId: 'a1',
      category: category,
    );
    final transaction = TransactionEntity.fromExpense(expense);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: TransactionListItem(
          transaction: transaction,
          currencySymbol: '\$',
          onTap: () {},
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(
      tile.contentPadding,
      EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingSmall / 2,
      ),
    );
  });
}
