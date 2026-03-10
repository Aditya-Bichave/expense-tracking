import re

f = 'test/features/group_expenses/presentation/pages/add_group_expense_page_test.dart'
with open(f, 'r') as file:
    content = file.read()

# Fix duplicate import
content = content.replace("import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_state.dart';", "")

# Fix MockCategoryManagementBloc inheritance (requires mocktail or bloc_test MockBloc)
# It says "The non-abstract class 'MockCategoryManagementBloc' is missing implementations for these members:"
# That means `MockBloc` from `bloc_test` wasn't imported properly, or it's just `Mock`.
if "import 'package:bloc_test/bloc_test.dart';" not in content:
    content = "import 'package:bloc_test/bloc_test.dart';\n" + content

content = content.replace("class MockCategoryManagementBloc extends MockBloc<CategoryManagementEvent, CategoryManagementState> implements CategoryManagementBloc {}", "class MockCategoryManagementBloc extends MockBloc<CategoryManagementEvent, CategoryManagementState> implements CategoryManagementBloc {}")

# Fix `,` syntax error
content = content.replace("],,", "],")

# Fix MultiBlocProvider
content = content.replace("""        BlocProvider<CategoryManagementBloc>.value(
          value: mockCategoryManagementBloc,
        )
      ],
      home:""", """        BlocProvider<CategoryManagementBloc>.value(
          value: mockCategoryManagementBloc,
        ),
      ],
      child:""")

content = content.replace("""    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<GroupExpensesBloc>.value(value: mockGroupExpensesBloc),
        BlocProvider<CategoryManagementBloc>.value(value: mockCategoryManagementBloc),
      ],
      home: """, """    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<GroupExpensesBloc>.value(value: mockGroupExpensesBloc),
        BlocProvider<CategoryManagementBloc>.value(value: mockCategoryManagementBloc),
      ],
      child: """)

content = content.replace("const CategoryManagementState", "CategoryManagementState")

with open(f, 'w') as file:
    file.write(content)
