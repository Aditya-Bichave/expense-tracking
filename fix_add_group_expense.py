import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

content = content.replace("import 'package:expense_tracker/features/categories/domain/entities/merchant_category.dart';", "import 'package:expense_tracker/features/categories/domain/entities/category.dart';\nimport 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';")
content = content.replace("MerchantCategory? _selectedCategory;", "Category? _selectedCategory;")

ui_part = """
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
content = re.sub(r'CategorySelectorTile\([\s\S]*?\),', ui_part.strip() + ',', content)

with open(f, 'w') as file:
    file.write(content)
