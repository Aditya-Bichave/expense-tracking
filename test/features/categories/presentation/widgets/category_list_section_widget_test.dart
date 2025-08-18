import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_item_widget.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  void onEdit(Category c);
  void onDelete(Category c);
  void onPersonalize(Category c);
}

void main() {
  late MockCallbacks mockCallbacks;
  final mockCategories = [
    const Category(
      id: '1',
      name: 'A Category',
      iconName: 'test',
      colorHex: '#111111',
      type: CategoryType.expense,
      isCustom: true,
    ),
    const Category(
      id: '2',
      name: 'B Category',
      iconName: 'test',
      colorHex: '#222222',
      type: CategoryType.expense,
      isCustom: true,
    ),
  ];

  setUp(() {
    mockCallbacks = MockCallbacks();
  });

  group('CategoryListSectionWidget', () {
    testWidgets('shows empty message when categories list is empty',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
            child: CategoryListSectionWidget(
          categories: const [],
          emptyMessage: 'No categories here',
          onEditCategory: mockCallbacks.onEdit,
          onDeleteCategory: mockCallbacks.onDelete,
          onPersonalizeCategory: mockCallbacks.onPersonalize,
        )),
      );
      expect(find.text('No categories here'), findsOneWidget);
    });

    testWidgets('renders a sorted list of CategoryListItemWidgets',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
            child: CategoryListSectionWidget(
          categories: mockCategories.reversed.toList(), // Provide unsorted list
          emptyMessage: '',
          onEditCategory: mockCallbacks.onEdit,
          onDeleteCategory: mockCallbacks.onDelete,
          onPersonalizeCategory: mockCallbacks.onPersonalize,
        )),
      );

      expect(find.byType(CategoryListItemWidget), findsNWidgets(2));

      // Verify that the list is sorted alphabetically
      final firstCategoryText = tester.widget<Text>(find.text('A Category'));
      final secondCategoryText = tester.widget<Text>(find.text('B Category'));

      final firstCategoryPos =
          tester.getTopLeft(find.byWidget(firstCategoryText));
      final secondCategoryPos =
          tester.getTopLeft(find.byWidget(secondCategoryText));

      expect(firstCategoryPos.dy < secondCategoryPos.dy, isTrue);
    });
  });
}
