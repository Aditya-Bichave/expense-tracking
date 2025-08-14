import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays provided categories without loading', (tester) async {
    final categories = const [
      Category(
        id: '1',
        name: 'Food',
        iconName: 'restaurant',
        colorHex: '#ffffff',
        type: CategoryType.expense,
        isCustom: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCategoryPicker(
              context,
              CategoryTypeFilter.expense,
              categories,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
  });
}
