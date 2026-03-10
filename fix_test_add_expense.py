import re

f = 'test/features/group_expenses/presentation/pages/add_group_expense_page_test.dart'
with open(f, 'r') as file:
    content = file.read()

# Replace the provider setup
import_str = """
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_state.dart';
"""
if 'CategoryManagementBloc' not in content:
    content = content.replace("import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';", "import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';\n" + import_str)

    mock_classes = """
class MockCategoryManagementBloc extends MockBloc<CategoryManagementEvent, CategoryManagementState> implements CategoryManagementBloc {}
"""
    content = content.replace("class MockGroupExpensesBloc", mock_classes + "\nclass MockGroupExpensesBloc")

    setup_vars = """
  late MockCategoryManagementBloc mockCategoryManagementBloc;
"""
    content = content.replace("late MockGroupExpensesBloc mockGroupExpensesBloc;", "late MockGroupExpensesBloc mockGroupExpensesBloc;\n" + setup_vars)

    setup_init = """
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    when(() => mockCategoryManagementBloc.state).thenReturn(const CategoryManagementState(status: CategoryManagementStatus.loaded));
"""
    content = content.replace("mockGroupExpensesBloc = MockGroupExpensesBloc();", "mockGroupExpensesBloc = MockGroupExpensesBloc();\n" + setup_init)

    # In pumpWidget:
    provider_replace = """
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<GroupExpensesBloc>.value(value: mockGroupExpensesBloc),
        BlocProvider<CategoryManagementBloc>.value(value: mockCategoryManagementBloc),
      ],
"""
    content = re.sub(r'providers:\s*\[.*?\]', provider_replace.strip(), content, flags=re.DOTALL)

with open(f, 'w') as file:
    file.write(content)
