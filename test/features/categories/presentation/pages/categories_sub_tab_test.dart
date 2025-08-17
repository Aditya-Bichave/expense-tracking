import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoryManagementBloc extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late CategoryManagementBloc mockBloc;
  late MockGoRouter mockGoRouter;

  final mockExpenseCategories = [
    Category(id: 'e1', name: 'Expense Cat', iconName: 'test', color: 0, type: CategoryType.expense),
  ];
  final mockIncomeCategories = [
    Category(id: 'i1', name: 'Income Cat', iconName: 'test', color: 0, type: CategoryType.income),
  ];

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
    mockGoRouter = MockGoRouter();
  });

  Widget buildTestWidget() {
    return BlocProvider.value(
      value: mockBloc,
      child: const CategoriesSubTab(),
    );
  }

  group('CategoriesSubTab', () {
    testWidgets('shows loading indicator', (tester) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(status: CategoryManagementStatus.loading));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders category lists in their respective tabs', (tester) async {
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

    testWidgets('"Manage Categories" button navigates', (tester) async {
      when(() => mockBloc.state).thenReturn(const CategoryManagementState(status: CategoryManagementStatus.loaded));
      when(() => mockGoRouter.pushNamed(RouteNames.manageCategories)).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(tester: tester, router: mockGoRouter, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('button_manage_categories')));

      verify(() => mockGoRouter.pushNamed(RouteNames.manageCategories)).called(1);
    });
  });
}
