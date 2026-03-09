import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.readlines()

print("LINES 65-80")
for i, line in enumerate(content[65:80]):
    print(f"{i+65}: {line.strip()}")
