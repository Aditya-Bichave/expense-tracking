import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late MockCategoryManagementBloc mockBloc;

  setUp(() {
    mockBloc = MockCategoryManagementBloc();
  });

  Widget createWidgetUnderTest({
    CategoryManagementState state = const CategoryManagementState(),
  }) {
    when(() => mockBloc.state).thenReturn(state);
    return MaterialApp(
      home: BlocProvider<CategoryManagementBloc>.value(
        value: mockBloc,
        child: const Scaffold(body: CategoriesSubTab()),
      ),
    );
  }

  testWidgets('CategoriesSubTab shows loading indicator', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        state: const CategoryManagementState(
          status: CategoryManagementStatus.loading,
        ),
      ),
    );
    expect(find.byType(BridgeCircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CategoriesSubTab renders category lists and updates state', (
    tester,
  ) async {
    final expenseCat = Category(
      id: '1',
      name: 'Expense',
      iconName: 'home',
      colorHex: '#000000',
      type: CategoryType.expense,
      isCustom: false,
    );
    final incomeCat = Category(
      id: '2',
      name: 'Income',
      iconName: 'work',
      colorHex: '#FFFFFF',
      type: CategoryType.income,
      isCustom: false,
    );

    final state = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
      predefinedExpenseCategories: [expenseCat],
      predefinedIncomeCategories: [incomeCat],
      customExpenseCategories: const [],
      customIncomeCategories: const [],
    );

    await tester.pumpWidget(createWidgetUnderTest(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Expense'), findsOneWidget);
  });

  testWidgets('CategoriesSubTab shows empty message when lists are empty', (
    tester,
  ) async {
    final state = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
      predefinedExpenseCategories: const [],
      predefinedIncomeCategories: const [],
      customExpenseCategories: const [],
      customIncomeCategories: const [],
    );

    await tester.pumpWidget(createWidgetUnderTest(state: state));
    await tester.pumpAndSettle();

    expect(find.text('No expense categories defined.'), findsOneWidget);
  });
}
