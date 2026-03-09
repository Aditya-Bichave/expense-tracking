import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# Add necessary import for categories
# Wait, do we have access to categories here? Usually it's in a Bloc.
# Oh wait, we need to pass categories. If we don't have them, we might need CategoryManagementBloc
import_bloc = "import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';\nimport 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_state.dart';"
if 'CategoryManagementBloc' not in content:
    content = content.replace("import 'package:flutter_bloc/flutter_bloc.dart';", "import 'package:flutter_bloc/flutter_bloc.dart';\n" + import_bloc)

ui_part = """
            BlocBuilder<CategoryManagementBloc, CategoryManagementState>(
              builder: (context, catState) {
                final categories = catState is CategoryManagementLoaded
                    ? catState.categories.where((c) => c.type == CategoryType.expense).toList()
                    : <Category>[];
                return CategorySelectorTile(
                  selectedCategory: _selectedCategory,
                  uncategorizedCategory: Category.uncategorized(),
                  onTap: () async {
                    final category = await showCategoryPicker(
                      context,
                      CategoryTypeFilter.expense,
                      categories,
                    );
                    if (category != null && mounted) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              }
            ),
"""
# Find the exact string we replaced before
old_ui_part = """
            CategorySelectorTile(
              selectedCategory: _selectedCategory,
              uncategorizedCategory: Category.uncategorized(),
              onTap: () async {
                final category = await showDialog<Category>(
                  context: context,
                  builder: (context) => const CategoryPickerDialog(),
                );
                if (category != null && mounted) {
                  setState(() => _selectedCategory = category);
                }
              },
            ),
"""
content = content.replace(old_ui_part.strip(), ui_part.strip())

with open(f, 'w') as file:
    file.write(content)
