import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# Fix the import
content = content.replace("import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_state.dart';", "")

content = content.replace("catState is CategoryManagementLoaded", "catState.status == CategoryManagementStatus.success")
content = content.replace("catState.categories.where", "catState.categories.where")

import_type = "import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';"
if import_type not in content:
    content = content.replace("import 'package:expense_tracker/features/categories/domain/entities/category.dart';", "import 'package:expense_tracker/features/categories/domain/entities/category.dart';\n" + import_type)

with open(f, 'w') as file:
    file.write(content)
