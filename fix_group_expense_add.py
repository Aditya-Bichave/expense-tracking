import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# We need to add a way to select category in AddGroupExpensePage.
# Does AddGroupExpensePage already have a lot of fields? Let's read it entirely first.
