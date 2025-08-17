import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  void onEdit();
  void onDelete();
  void onPersonalize();
}

void main() {
  late MockCallbacks mockCallbacks;

  final customCategory = Category(
      id: 'c1', name: 'Custom', iconName: 'test', color: 0, isCustom: true);
  final predefinedCategory = Category(
      id: 'p1',
      name: 'Predefined',
      iconName: 'test',
      color: 0,
      isCustom: false);

  setUp(() {
    mockCallbacks = MockCallbacks();
  });

  group('CategoryListItemWidget', () {
    testWidgets('renders category name and icon', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: Material(
              child: CategoryListItemWidget(category: customCategory)));
      expect(find.text('Custom'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows Edit and Delete buttons for custom categories',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: Material(
              child: CategoryListItemWidget(category: customCategory)));
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows Personalize button for predefined categories',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: Material(
              child: CategoryListItemWidget(category: predefinedCategory)));
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('calls onEdit and onDelete callbacks for custom categories',
        (tester) async {
      when(() => mockCallbacks.onEdit()).thenAnswer((_) {});
      when(() => mockCallbacks.onDelete()).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
            child: CategoryListItemWidget(
          category: customCategory,
          onEdit: mockCallbacks.onEdit,
          onDelete: mockCallbacks.onDelete,
        )),
      );

      await tester.tap(find.byKey(const ValueKey('button_edit_c1')));
      verify(() => mockCallbacks.onEdit()).called(1);

      await tester.tap(find.byKey(const ValueKey('button_delete_c1')));
      verify(() => mockCallbacks.onDelete()).called(1);
    });
  });
}
