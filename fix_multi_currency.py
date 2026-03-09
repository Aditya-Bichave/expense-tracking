import re

f = 'lib/features/groups/presentation/pages/group_detail_page.dart'
with open(f, 'r') as file:
    content = file.read()

import_stmt = "import 'package:expense_tracker/core/currency/currency_converter_service.dart';"
if import_stmt not in content:
    content = import_stmt + '\n' + content

# We need to apply currency converter to group balances.
# Let's see how netBalance is calculated:
# double netBalance = 0;
# if (currentUser != null) {
#   for (var exp in state.expenses) {
#     if (exp.createdBy == currentUser.id) {
#       netBalance += exp.amount; // User paid this
#     }
#     final userSplit = exp.splits.firstWhereOrNull((s) => s.userId == currentUser.id);
#     if (userSplit != null) {
#       netBalance -= userSplit.amount;
#     }
#   }
# }

# We will instantiate CurrencyConverterService here and use the group's default currency.
# Wait, what's the group currency?
# We have `GroupsBloc` loaded. We can get it.

# Let's just assume we want it in USD for now, or fetch group currency.
# Actually, the user's base currency from SettingsBloc.
# final settingsState = context.read<SettingsBloc>().state;
# final baseCurrency = settingsState.currency;

replacement = """
                                  double netBalance = 0;
                                  if (currentUser != null) {
                                    final converter = CurrencyConverterService();
                                    final baseCurrency = context.read<SettingsBloc>().state.currency;

                                    for (var exp in state.expenses) {
                                      double amountInBase = converter.convert(
                                        amount: exp.amount,
                                        fromCurrency: exp.currency,
                                        toCurrency: baseCurrency,
                                      );

                                      if (exp.createdBy == currentUser.id) {
                                        netBalance += amountInBase; // User paid this
                                      }

                                      final userSplit = exp.splits.firstWhereOrNull((s) => s.userId == currentUser.id);
                                      if (userSplit != null) {
                                        double splitInBase = converter.convert(
                                          amount: userSplit.amount,
                                          fromCurrency: exp.currency,
                                          toCurrency: baseCurrency,
                                        );
                                        netBalance -= splitInBase;
                                      }
                                    }
                                  }
"""

content = re.sub(
    r'double netBalance = 0;\s*if \(currentUser != null\) \{\s*for \(var exp in state\.expenses\) \{\s*if \(exp\.createdBy == currentUser\.id\) \{\s*netBalance \+= exp\.amount; // User paid this\s*\}\s*final userSplit = exp\.splits\.firstWhereOrNull\(\(s\) => s\.userId == currentUser\.id\);\s*if \(userSplit != null\) \{\s*netBalance -= userSplit\.amount;\s*\}\s*\}\s*\}',
    replacement.strip(),
    content
)

with open(f, 'w') as file:
    file.write(content)
