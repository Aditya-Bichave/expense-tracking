import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late CategoryManagementBloc mockBloc;

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<Uuid>()) {
      getIt.registerLazySingleton<Uuid>(() => const Uuid());
      addTearDown(() => getIt.unregister<Uuid>());
    }
  });

  group('AddEditCategoryScreen', () {
    testWidgets('renders CategoryForm and correct title for "Add" mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: mockBloc,
            child: const AddEditCategoryScreen(),
          ),
        ),
      );
      expect(find.text('Add Category'), findsWidgets);
      expect(find.byType(CategoryForm), findsOneWidget);
    });

    testWidgets('renders correct title for "Edit" mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
      expect(find.text('Edit Category'), findsOneWidget);
    });

    testWidgets('submit calls AddCategory event when adding', (tester) async {
      when(() => mockBloc.add(any())).thenAnswer((_) {});
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: mockBloc,
            child: const AddEditCategoryScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'New Category',
      );
      await tester.tap(find.byKey(const ValueKey('button_submit')));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<AddCategory>()))).called(1);
    });

    testWidgets('parent tile reads "None" until a parent is picked', (
      tester,
    ) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: mockBloc,
            child: const AddEditCategoryScreen(),
          ),
        ),
      );

      expect(find.text('Parent Category'), findsOneWidget);
      expect(find.text('None (Top Level)'), findsOneWidget);
    });

    testWidgets('picker offers same-type top-level categories and stores the '
        'choice by name', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const CategoryManagementState(
          status: CategoryManagementStatus.loaded,
          customExpenseCategories: [
            Category(
              id: 'p1',
              name: 'Groceries',
              iconName: 'cart',
              colorHex: '#FF0000',
              type: CategoryType.expense,
              isCustom: true,
            ),
            // Already nested, so it cannot itself be a parent.
            Category(
              id: 'c1',
              name: 'Fruit',
              iconName: 'cart',
              colorHex: '#FF0000',
              type: CategoryType.expense,
              isCustom: true,
              parentCategoryId: 'p1',
            ),
          ],
          customIncomeCategories: [
            // Wrong type, so it must not be offered.
            Category(
              id: 'i1',
              name: 'Salary',
              iconName: 'cash',
              colorHex: '#00FF00',
              type: CategoryType.income,
              isCustom: true,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: mockBloc,
            child: const AddEditCategoryScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Parent Category'));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Fruit'), findsNothing);
      expect(find.text('Salary'), findsNothing);

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // The tile shows the parent's name, not its id.
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('None (Top Level)'), findsNothing);
      expect(find.text('p1'), findsNothing);
    });

    testWidgets('picker explains itself when there are no eligible parents', (
      tester,
    ) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: mockBloc,
            child: const AddEditCategoryScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Parent Category'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No other top-level categories'),
        findsOneWidget,
      );
    });
  });
}
