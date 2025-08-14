import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/recurring_rule_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RecurringRuleListPage extends StatelessWidget {
  const RecurringRuleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
      ),
      body: BlocProvider(
        create: (context) => sl<RecurringListBloc>()..add(LoadRecurringRules()),
        child: BlocBuilder<RecurringListBloc, RecurringListState>(
          builder: (context, state) {
            if (state is RecurringListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RecurringListError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is RecurringListLoaded) {
              if (state.rules.isEmpty) {
                return const Center(child: Text('No recurring rules found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: state.rules.length,
                itemBuilder: (context, index) {
                  final rule = state.rules[index];
                  return Dismissible(
                    key: Key(rule.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete_sweep_outlined,
                          color:
                              Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    confirmDismiss: (_) async {
                      final confirmed = await AppDialogs.showConfirmation(
                        context,
                        title: "Confirm Deletion",
                        content:
                            "Are you sure you want to delete the recurring rule for '${rule.description}'? This will not affect any transactions that have already been generated.",
                        confirmText: "Delete",
                      );
                      if (confirmed == true && context.mounted) {
                        context
                            .read<RecurringListBloc>()
                            .add(DeleteRule(rule.id));
                        return true;
                      }
                      return false;
                    },
                    child: RecurringRuleListItem(
                      rule: rule,
                      onTap: () {
                        context.push(
                          '${RouteNames.recurring}/${RouteNames.editRecurring}/${rule.id}',
                          extra: rule,
                        );
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('Press the button to load rules.'));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('${RouteNames.recurring}/${RouteNames.addRecurring}');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
