import re

f = 'lib/features/group_expenses/data/models/group_expense_model.dart'
with open(f, 'r') as file:
    content = file.read()

if 'final String? categoryId;' not in content:
    content = content.replace("final List<ExpenseSplitModel> splits;", "final List<ExpenseSplitModel> splits;\n  @HiveField(11)\n  final String? categoryId;")
    content = content.replace("this.splits = const [],", "this.splits = const [],\n    this.categoryId,")
    content = content.replace("splits: entity.splits", "categoryId: entity.categoryId,\n      splits: entity.splits")
    content = content.replace("splits: splits.map((e) => e.toEntity()).toList(),", "splits: splits.map((e) => e.toEntity()).toList(),\n      categoryId: categoryId,")

    with open(f, 'w') as file:
        file.write(content)
