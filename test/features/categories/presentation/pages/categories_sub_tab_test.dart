import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart';
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

  final mockExpenseCategories = [
    const Category(
      id: 'e1',
      name: 'Expense Cat',
      iconName: 'test',
      colorHex: '#ff0000',
      type: CategoryType.expense,
      isCustom: true,
    ),
  ];
  final mockIncomeCategories = [
    const Category(
      id: 'i1',
      name: 'Income Cat',
      iconName: 'test',
      colorHex: '#00ff00',
      type: CategoryType.income,
      isCustom: true,
    ),
  ];

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
  });

  Widget buildTestWidget() {
    return BlocProvider.value(
      value: mockBloc,
      child: const CategoriesSubTab(),
    );
  }

  group('CategoriesSubTab', () {
    testWidgets('shows loading indicator', (tester) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(
          status: CategoryManagementStatus.loading));
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders category lists in their respective tabs',
        (tester) async {
      when(() => mockBloc.state).thenReturn(CategoryManagementState(
        status: CategoryManagementStatus.loaded,
        customExpenseCategories: mockExpenseCategories,
        customIncomeCategories: mockIncomeCategories,
      ));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      // Expense tab is visible by default
      expect(find.text('Expense Cat'), findsOneWidget);
      expect(find.text('Income Cat'), findsNothing);

      // Switch to Income tab
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.text('Expense Cat'), findsNothing);
      expect(find.text('Income Cat'), findsOneWidget);
    });

    testWidgets('has "Manage Categories" button', (tester) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(
          status: CategoryManagementStatus.loaded));

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      expect(find.byKey(const ValueKey('button_manage_categories')),
          findsOneWidget);
    });
  });
}
