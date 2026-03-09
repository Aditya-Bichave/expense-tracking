import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# Replace Category.uncategorized() with Category.uncategorized
content = content.replace("Category.uncategorized()", "Category.uncategorized")

with open(f, 'w') as file:
    file.write(content)
