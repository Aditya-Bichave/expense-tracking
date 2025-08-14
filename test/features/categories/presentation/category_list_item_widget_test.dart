import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edit and delete buttons have minimum touch size', (
    tester,
  ) async {
    const category = Category(
      id: '1',
      name: 'Food',
      iconName: 'question',
      colorHex: '#FF0000',
      type: CategoryType.expense,
      isCustom: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListItemWidget(
          category: category,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );

    final editFinder = find.byTooltip('Edit Category');
    final deleteFinder = find.byTooltip('Delete Category');

    expect(tester.getSize(editFinder).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(editFinder).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(deleteFinder).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(deleteFinder).height, greaterThanOrEqualTo(48));
  });
}
