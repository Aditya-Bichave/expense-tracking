import re

f = 'lib/features/group_expenses/presentation/pages/add_group_expense_page.dart'
with open(f, 'r') as file:
    content = file.read()

# Add Category Selector
import_stmts = """import 'package:expense_tracker/features/categories/domain/entities/merchant_category.dart';
import 'package:expense_tracker/core/widgets/category_selector_tile.dart';
"""
if 'MerchantCategory' not in content:
    content = content.replace("import 'package:flutter/material.dart';", import_stmts + "import 'package:flutter/material.dart';")

state_vars = """
  final _uuid = const Uuid();
  MerchantCategory? _selectedCategory;
"""
content = content.replace("final _uuid = const Uuid();", state_vars)

ui_part = """
            TextField(
              key: const Key('group_expense_amount_field'),
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            CategorySelectorTile(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
"""
content = content.replace("""            TextField(
              key: const Key('group_expense_amount_field'),
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),""", ui_part)

expense_creation = """
                    final expense = GroupExpense(
                      id: _uuid.v4(),
                      groupId: widget.groupId,
                      createdBy: authState.user.id,
                      title: title,
                      amount: amount,
                      currency: 'USD',
                      occurredAt: DateTime.now(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      categoryId: _selectedCategory?.id,
                      payers: [
                        ExpensePayer(userId: authState.user.id, amount: amount),
                      ],
                      splits: [],
                    );
"""
content = re.sub(r'final expense = GroupExpense\(.*?\);', expense_creation.strip(), content, flags=re.DOTALL)

with open(f, 'w') as file:
    file.write(content)
