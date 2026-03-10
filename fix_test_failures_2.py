import re

# Fix GroupExpenseModel toJson test
f = 'test/features/group_expenses/data/models/group_expense_model_test.dart'
try:
    with open(f, 'r') as file:
        content = file.read()

    # We added `categoryId` to GroupExpenseModel
    content = content.replace("'occurred_at': tDate.toIso8601String(),", "'occurred_at': tDate.toIso8601String(),\n      'category_id': null,")
    content = content.replace("this.splits = const [],", "this.splits = const [], this.categoryId,")

    with open(f, 'w') as file:
        file.write(content)
except Exception as e:
    print(e)


# Fix AddGroupExpensePage test
f = 'test/features/group_expenses/presentation/pages/add_group_expense_page_test.dart'
try:
    with open(f, 'r') as file:
        content = file.read()

    # We added CategorySelectorTile and CategoryManagementBloc dependency
    if 'CategoryManagementBloc' not in content:
        content = content.replace("class MockGroupExpensesBloc", "class MockCategoryManagementBloc extends MockBloc<CategoryManagementEvent, CategoryManagementState> implements CategoryManagementBloc {}\nclass MockGroupExpensesBloc")
        content = content.replace("import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';", "import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';\nimport 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';\nimport 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_state.dart';")
        content = content.replace("late MockGroupExpensesBloc mockGroupExpensesBloc;", "late MockGroupExpensesBloc mockGroupExpensesBloc;\n  late MockCategoryManagementBloc mockCategoryManagementBloc;")
        content = content.replace("mockGroupExpensesBloc = MockGroupExpensesBloc();", "mockGroupExpensesBloc = MockGroupExpensesBloc();\n    mockCategoryManagementBloc = MockCategoryManagementBloc();\n    when(() => mockCategoryManagementBloc.state).thenReturn(const CategoryManagementState());")

        # Inject to MultiBlocProvider or BlocProvider
        content = content.replace("BlocProvider<GroupExpensesBloc>.value(\n          value: mockGroupExpensesBloc,", "BlocProvider<GroupExpensesBloc>.value(\n          value: mockGroupExpensesBloc,\n        ),\n        BlocProvider<CategoryManagementBloc>.value(\n          value: mockCategoryManagementBloc,")
        content = content.replace("BlocProvider<GroupExpensesBloc>.value(", "MultiBlocProvider(\n      providers: [\n        BlocProvider<GroupExpensesBloc>.value(")
        # Note: the widget tree is usually:
        # MultiBlocProvider( providers: [ BlocProvider.value... ] ) or similar.
        # Let's write a targeted regex

except Exception as e:
    print(e)
