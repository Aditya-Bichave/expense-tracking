import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# Fix CategoryManagementLoaded
content = content.replace("import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_state.dart';", "")

# Missing category type import
import_type = "import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';"
if import_type not in content:
    content = content.replace("import 'package:expense_tracker/features/categories/domain/entities/category.dart';", "import 'package:expense_tracker/features/categories/domain/entities/category.dart';\n" + import_type)

# Instead of checking state is CategoryManagementLoaded, which might be named differently
# Let's check what state CategoryManagementBloc emits:
# Usually it's CategoryManagementState
# Let's just use empty categories for now to bypass if it's too complex or we can look up the actual state class.
