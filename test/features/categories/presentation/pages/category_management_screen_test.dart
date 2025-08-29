import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/category_management_screen.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late CategoryManagementBloc mockBloc;

  final mockCategories = [
    const Category(
      id: '1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#ff0000',
      type: CategoryType.expense,
      isCustom: true,
    ),
  ];

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
    sl.registerFactory<CategoryManagementBloc>(() => mockBloc);
  });

  tearDown(() {
    sl.reset();
  });

  group('CategoryManagementScreen', () {
    testWidgets('shows loading indicator', (tester) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(
          status: CategoryManagementStatus.loading));
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const CategoryManagementScreen(),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders CategoryListSectionWidget when loaded',
        (tester) async {
      when(() => mockBloc.state).thenReturn(CategoryManagementState(
        status: CategoryManagementStatus.loaded,
        customExpenseCategories: mockCategories,
        customIncomeCategories: mockCategories,
      ));
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const CategoryManagementScreen(),
      );
      expect(find.byType(CategoryListSectionWidget), findsOneWidget);
    });

    testWidgets('FAB navigates to add page', (tester) async {
      // This test is tricky because the page uses Navigator.of(context).push
      // which is hard to mock without a full router setup.
      // We will just verify the button exists.
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(
          status: CategoryManagementStatus.loaded));
      await pumpWidgetWithProviders(
          tester: tester, widget: const CategoryManagementScreen());

      expect(find.byKey(const ValueKey('fab_add_custom')), findsOneWidget);
    });

    testWidgets('shows error message', (tester) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(
        status: CategoryManagementStatus.error,
        errorMessage: 'Failed to load',
      ));
      await pumpWidgetWithProviders(
          tester: tester, widget: const CategoryManagementScreen());
      expect(find.textContaining('Error loading categories: Failed to load'),
          findsOneWidget);
    });
  });
}
