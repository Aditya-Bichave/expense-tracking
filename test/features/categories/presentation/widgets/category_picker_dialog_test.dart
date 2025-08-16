import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final mockCategories = [
    Category(id: '1', name: 'Food', iconName: 'food', color: 0),
    Category(id: '2', name: 'Shopping', iconName: 'shopping', color: 0),
  ];

  group('CategoryPickerDialogContent', () {
    testWidgets('renders a list of categories', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CategoryPickerDialogContent(
            categoryType: CategoryTypeFilter.expense,
            categories: mockCategories,
          ),
        ),
      ));

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('filters categories based on search', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CategoryPickerDialogContent(
            categoryType: CategoryTypeFilter.expense,
            categories: mockCategories,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'shop');
      await tester.pump();

      expect(find.text('Food'), findsNothing);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('tapping a category pops with the selected category', (tester) async {
      Category? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showCategoryPicker(context, CategoryTypeFilter.expense, mockCategories);
              },
              child: const Text('Show'),
            ),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(result, mockCategories.first);
    });

    testWidgets('tapping "Add New" button navigates', (tester) async {
      final mockGoRouter = MockGoRouter();
      when(() => mockGoRouter.push(any())).thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        home: MockGoRouterProvider(
          goRouter: mockGoRouter,
          child: const Scaffold(
            body: CategoryPickerDialogContent(
              categoryType: CategoryTypeFilter.expense,
              categories: [],
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('button_add_new_category')));

      verify(() => mockGoRouter.push(any(that: contains('add-category')))).called(1);
    });
  });
}
