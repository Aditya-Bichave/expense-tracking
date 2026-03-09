import re

f = 'lib/features/group_expenses/domain/entities/group_expense.dart'
with open(f, 'r') as file:
    content = file.read()

if 'final String? categoryId;' not in content:
    content = content.replace("final DateTime updatedAt;", "final DateTime updatedAt;\n  final String? categoryId;")
    content = content.replace("required this.updatedAt,", "required this.updatedAt,\n    this.categoryId,")
    content = content.replace("updatedAt,\n    payers,", "updatedAt,\n    categoryId,\n    payers,")
    with open(f, 'w') as file:
        file.write(content)
