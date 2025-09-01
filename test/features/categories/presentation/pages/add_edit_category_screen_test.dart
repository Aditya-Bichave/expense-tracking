import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/mock_helpers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late CategoryManagementBloc mockBloc;

  setUpAll(() {
    Testhelpers.registerFallbacks();
  });

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<Uuid>()) {
      getIt.registerLazySingleton<Uuid>(() => const Uuid());
    }
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('AddEditCategoryScreen', () {
    testWidgets('renders CategoryForm and correct title for "Add" mode',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditCategoryScreen(),
        blocProviders: [
          BlocProvider<CategoryManagementBloc>.value(value: mockBloc),
        ],
      );

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Add Category')), findsOneWidget);
      expect(find.byType(CategoryForm), findsOneWidget);
    });

    testWidgets('renders correct title for "Edit" mode', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AddEditCategoryScreen(
          initialCategory: const Category(
            id: '1',
            name: 'Test',
            iconName: 'test',
            colorHex: '#ffffff',
            type: CategoryType.expense,
            isCustom: true,
          ),
        ),
        blocProviders: [
          BlocProvider<CategoryManagementBloc>.value(value: mockBloc),
        ],
      );
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Edit Category')), findsOneWidget);
    });

    testWidgets('submit calls AddCategory event when adding', (tester) async {
      when(() => mockBloc.add(any())).thenAnswer((_) {});
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditCategoryScreen(),
        blocProviders: [
          BlocProvider<CategoryManagementBloc>.value(value: mockBloc),
        ],
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Category Name'), 'New Category');
      await tester.tap(find.byKey(const ValueKey('button_submit')));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<AddCategory>()))).called(1);
    });
  });
}
