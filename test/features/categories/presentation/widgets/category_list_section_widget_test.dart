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
    testWidgets('shows empty message when categories list is empty', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategoryListSectionWidget(
            categories: const [],
            emptyMessage: 'No categories here',
            onEditCategory: mockCallbacks.onEdit,
            onDeleteCategory: mockCallbacks.onDelete,
            onPersonalizeCategory: mockCallbacks.onPersonalize,
          ),
        ),
      );
      expect(find.text('No categories here'), findsOneWidget);
    });

    testWidgets('renders a sorted list of CategoryListItemWidgets', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategoryListSectionWidget(
            categories: mockCategories.reversed
                .toList(), // Provide unsorted list
            emptyMessage: '',
            onEditCategory: mockCallbacks.onEdit,
            onDeleteCategory: mockCallbacks.onDelete,
            onPersonalizeCategory: mockCallbacks.onPersonalize,
          ),
        ),
      );

      expect(find.byType(CategoryListItemWidget), findsNWidgets(2));

      // Verify that the list is sorted alphabetically
      final firstCategoryText = tester.widget<Text>(find.text('A Category'));
      final secondCategoryText = tester.widget<Text>(find.text('B Category'));

      final firstCategoryPos = tester.getTopLeft(
        find.byWidget(firstCategoryText),
      );
      final secondCategoryPos = tester.getTopLeft(
        find.byWidget(secondCategoryText),
      );

      expect(firstCategoryPos.dy < secondCategoryPos.dy, isTrue);
    });

    testWidgets('updates list when categories change using didUpdateWidget', (tester) async {
      final initialCategories = [
        const Category(
          id: '1',
          name: 'Z Category',
          iconName: 'test',
          colorHex: '#111111',
          type: CategoryType.expense,
          isCustom: true,
        ),
      ];

      final updatedCategories = [
        ...initialCategories,
        const Category(
          id: '2',
          name: 'A Category',
          iconName: 'test',
          colorHex: '#222222',
          type: CategoryType.expense,
          isCustom: true,
        ),
      ];

      Widget buildWidget(List<Category> categories) {
        return Material(
          child: CategoryListSectionWidget(
            categories: categories,
            emptyMessage: '',
            onEditCategory: mockCallbacks.onEdit,
            onDeleteCategory: mockCallbacks.onDelete,
            onPersonalizeCategory: mockCallbacks.onPersonalize,
          ),
        );
      }

      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildWidget(initialCategories),
      );

      expect(find.text('Z Category'), findsOneWidget);
      expect(find.text('A Category'), findsNothing);

      // Re-pump with updated categories to trigger didUpdateWidget
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildWidget(updatedCategories),
      );

      expect(find.text('A Category'), findsOneWidget);
      expect(find.text('Z Category'), findsOneWidget);

      // Ensure the sort logic in didUpdateWidget actually sorted them
      final aText = tester.widget<Text>(find.text('A Category'));
      final zText = tester.widget<Text>(find.text('Z Category'));

      final aPos = tester.getTopLeft(find.byWidget(aText));
      final zPos = tester.getTopLeft(find.byWidget(zText));

      expect(aPos.dy < zPos.dy, isTrue);

      // trigger callbacks to get coverage
      final editBtn = find.byKey(const ValueKey('button_edit_1')).first;
      await tester.tap(editBtn);
      verify(() => mockCallbacks.onEdit(any())).called(1);

      final deleteBtn = find.byKey(const ValueKey('button_delete_1')).first;
      await tester.tap(deleteBtn);
      verify(() => mockCallbacks.onDelete(any())).called(1);

      final personalizeBtn = find.byIcon(Icons.palette_outlined).first;
      // create a predefined category to trigger personalize button
      final predefinedCategories = [
        const Category(
          id: '3',
          name: 'Predefined Category',
          iconName: 'test',
          colorHex: '#333333',
          type: CategoryType.expense,
          isCustom: false,
        ),
      ];

      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildWidget(predefinedCategories),
      );

      final personalizeBtnFound = find.byIcon(Icons.palette_outlined).first;
      await tester.tap(personalizeBtnFound);
      verify(() => mockCallbacks.onPersonalize(any())).called(1);
    });
  });
}
