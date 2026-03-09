import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

content = content.replace("),,", "),")

with open(f, 'w') as file:
    file.write(content)
