import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late CategoryManagementBloc mockBloc;

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
  });

  group('AddEditCategoryScreen', () {
    testWidgets('renders CategoryForm and correct title for "Add" mode',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
          value: mockBloc,
          child: const AddEditCategoryScreen(),
        ),
      ));
      expect(find.text('Add Category'), findsOneWidget);
      expect(find.byType(CategoryForm), findsOneWidget);
    });

    testWidgets('renders correct title for "Edit" mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
          value: mockBloc,
          child: AddEditCategoryScreen(
            initialCategory: const Category(
              id: '1',
              name: 'Test',
              iconName: 'test',
              colorHex: '#ffffff',
              type: CategoryType.expense,
              isCustom: true,
            ),
          ),
        ),
      ));
      expect(find.text('Edit Category'), findsOneWidget);
    });

    testWidgets('submit calls AddCategory event when adding', (tester) async {
      when(() => mockBloc.add(any())).thenAnswer((_) {});
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
          value: mockBloc,
          child: const AddEditCategoryScreen(),
        ),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Category Name'), 'New Category');
      await tester.tap(find.byKey(const ValueKey('button_submit')));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<AddCategory>()))).called(1);
    });
  });
}
