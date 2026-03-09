import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# Fix categories getter
content = content.replace("catState.categories.where((c) => c.type == CategoryType.expense).toList();",
                          "catState.allExpenseCategories;")

# Instead of checking showCategoryPicker which is apparently not a function or something...
# Let's import CategoryPickerDialog and show Modal Bottom Sheet directly since I might have misunderstood the `showCategoryPicker` signature or it was moved.
ui_part_new = """
            BlocBuilder<CategoryManagementBloc, CategoryManagementState>(
              builder: (context, catState) {
                final categories = catState.status == CategoryManagementStatus.loaded
                    ? catState.allExpenseCategories
                    : <Category>[];
                return CategorySelectorTile(
                  selectedCategory: _selectedCategory,
                  uncategorizedCategory: Category.uncategorized(),
                  onTap: () async {
                    final category = await showModalBottomSheet<Category?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => CategoryPickerDialogContent(
                        categoryType: CategoryTypeFilter.expense,
                        categories: categories,
                      ),
                    );
                    if (category != null && mounted) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              }
            ),
"""

# Let's just find and replace the whole BlocBuilder block
start_idx = content.find("BlocBuilder<CategoryManagementBloc")
end_idx = content.find("),", start_idx) # finds the end of BlocBuilder
# It's better to use regex or replace the specific block.
content = re.sub(r"BlocBuilder<CategoryManagementBloc.*?}\s*\),", ui_part_new.strip() + ",", content, flags=re.DOTALL)

with open(f, 'w') as file:
    file.write(content)
