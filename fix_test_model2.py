f = 'test/features/group_expenses/data/models/group_expense_model_test.dart'
with open(f, 'r') as file:
    content = file.read()
content = content.replace(
"""          'splits': [
            {'userId': 'u1', 'amount': 50.0, 'splitTypeValue': 'equal'},
          ],
        };""",
"""          'splits': [
            {'userId': 'u1', 'amount': 50.0, 'splitTypeValue': 'equal'},
          ],
          'category_id': null,
        };"""
)
with open(f, 'w') as file:
    file.write(content)
