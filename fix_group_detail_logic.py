import re

f = 'lib/features/groups/presentation/pages/group_detail_page.dart'
with open(f, 'r') as file:
    content = file.read()

import_stmt = "import 'package:expense_tracker/features/groups/presentation/widgets/group_balance_card.dart';"
if import_stmt not in content:
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
                                      // If user is part of the split, subtract their share.
                                      // The splits might be a list. Let's find the split for this user.
                                      try {
                                        final userSplit = exp.splits.firstWhere((s) => s.userId == currentUser.id);
                                        netBalance -= userSplit.amount;
                                      } catch (e) {
                                        // User not in split
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

with open(f, 'w') as file:
    file.write(content)
