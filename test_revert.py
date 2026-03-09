import re

f = 'lib/features/groups/presentation/pages/group_detail_page.dart'
with open(f, 'r') as file:
    content = file.read()

import_stmt = "import 'package:expense_tracker/features/groups/presentation/widgets/group_balance_card.dart';\nimport 'package:collection/collection.dart';"
if 'group_balance_card.dart' not in content:
    content = content.replace("import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';", "import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';\n" + import_stmt)

replacement = """
                                if (state is GroupExpensesLoading) {
                                  return const AppLoadingIndicator();
                                } else if (state is GroupExpensesLoaded) {
                                  final currentUser = context.read<AuthBloc>().state is AuthAuthenticated
                                      ? (context.read<AuthBloc>().state as AuthAuthenticated).user
                                      : null;

                                  double netBalance = 0;
                                  if (currentUser != null) {
                                    for (var exp in state.expenses) {
                                      if (exp.createdBy == currentUser.id) {
                                        netBalance += exp.amount; // User paid this
                                      }
                                      final userSplit = exp.splits.firstWhereOrNull((s) => s.userId == currentUser.id);
                                      if (userSplit != null) {
                                        netBalance -= userSplit.amount;
                                      }
                                    }
                                  }

                                  return Column(
                                    children: [
                                      if (currentUser != null)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: GroupBalanceCard(netBalance: netBalance),
                                        ),
                                      Expanded(
                                        child: state.expenses.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No expenses yet.',
                                                  style: kit.typography.body,
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: state.expenses.length,
                                                itemBuilder: (context, index) {
                                                  final expense = state.expenses[index];
                                                  return AppListTile(
"""

# Now we must make sure we don't break the brackets.
# The original code has:
#                                 } else if (state is GroupExpensesLoaded) {
#                                   if (state.expenses.isEmpty) {
#                                     return Center(
#                                       child: Text(
#                                         'No expenses yet.',
#                                         style: kit.typography.body,
#                                       ),
#                                     );
#                                   }
#                                   return ListView.builder(
#                                     itemCount: state.expenses.length,
#                                     itemBuilder: (context, index) {
#                                       final expense = state.expenses[index];
#                                       return AppListTile(

content = re.sub(
    r"""\s*if \(state is GroupExpensesLoading\) \{
\s*return const AppLoadingIndicator\(\);
\s*\} else if \(state is GroupExpensesLoaded\) \{
\s*if \(state\.expenses\.isEmpty\) \{
\s*return Center\(
\s*child: Text\(
\s*'No expenses yet\.',
\s*style: kit\.typography\.body,
\s*\),
\s*\);
\s*\}
\s*return ListView\.builder\(
\s*itemCount: state\.expenses\.length,
\s*itemBuilder: \(context, index\) \{
\s*final expense = state\.expenses\[index\];
\s*return AppListTile\(""", replacement, content)

# But we need to close `Column` and `Expanded`!
# Let's search for `return const SizedBox.shrink();` which is the fallback of `BlocBuilder<GroupExpensesBloc>`.
# Before that, there's `});` which closes `ListView.builder`.
# Wait, `itemBuilder` returns `AppListTile(...)`
# We need to wrap `ListView.builder` properly.

content = content.replace("                                    },\n                                  );\n                                }", "                                    },\n                                  ),\n                                      ),\n                                    ],\n                                  );\n                                }")

with open(f, 'w') as file:
    file.write(content)
