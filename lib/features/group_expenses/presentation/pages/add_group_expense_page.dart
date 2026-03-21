import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_event.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_state.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';

class AddGroupExpensePage extends StatefulWidget {
  final String groupId;
  final String currency;
  final GroupExpense? initialExpense;

  const AddGroupExpensePage({
    super.key,
    required this.groupId,
    required this.currency,
    this.initialExpense,
  });

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  final Map<String, TextEditingController> _payerControllers = {};
  final Map<String, TextEditingController> _splitControllers = {};

  final Map<String, double> _payerAmounts = {};
  final Map<String, double> _splitAmounts = {};

  bool _isSplitEqually = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      _titleController.text = widget.initialExpense!.title;
      _amountController.text = widget.initialExpense!.amount.toString();

      for (var payer in widget.initialExpense!.payers) {
        _payerAmounts[payer.userId] = payer.amount;
        _getPayerController(payer.userId, payer.amount);
      }

      for (var split in widget.initialExpense!.splits) {
        _splitAmounts[split.userId] = split.amount;
        _getSplitController(split.userId, split.amount);
        if (split.splitType.value != 'equal') {
          _isSplitEqually = false;
        }
      }
    }
  }

  TextEditingController _getPayerController(String userId, double? amount) {
    if (!_payerControllers.containsKey(userId)) {
      _payerControllers[userId] = TextEditingController(
        text: amount?.toStringAsFixed(2) ?? '',
      );
    }
    return _payerControllers[userId]!;
  }

  TextEditingController _getSplitController(String userId, double? amount) {
    if (!_splitControllers.containsKey(userId)) {
      _splitControllers[userId] = TextEditingController(
        text: amount?.toStringAsFixed(2) ?? '',
      );
    }
    return _splitControllers[userId]!;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (var controller in _payerControllers.values) {
      controller.dispose();
    }
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountStr = _amountController.text.trim();

    if (title.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and amount')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }
    final currentUser = authState.user;

    final membersState = context.read<GroupMembersBloc>().state;
    final members = membersState.members;

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members found in the group')),
      );
      return;
    }

    if (_payerAmounts.isEmpty) {
      _payerAmounts[currentUser.id] = amount;
    } else {
      final totalPayer = _payerAmounts.values.fold(0.0, (a, b) => a + b);
      if ((totalPayer - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payer amounts do not equal total amount'),
          ),
        );
        return;
      }
    }

    if (_isSplitEqually) {
      final splitAmount = amount / members.length;
      for (final member in members) {
        _splitAmounts[member.userId] = splitAmount;
      }
    } else {
      final totalSplit = _splitAmounts.values.fold(0.0, (a, b) => a + b);
      if ((totalSplit - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split amounts do not equal total amount'),
          ),
        );
        return;
      }
    }

    final expense = GroupExpense(
      id: widget.initialExpense?.id ?? const Uuid().v4(),
      groupId: widget.groupId,
      createdBy: widget.initialExpense?.createdBy ?? currentUser.id,
      title: title,
      amount: amount,
      currency: widget.currency,
      occurredAt: widget.initialExpense?.occurredAt ?? DateTime.now(),
      createdAt: widget.initialExpense?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      payers: _payerAmounts.entries
          .map((e) => ExpensePayer(userId: e.key, amount: e.value))
          .toList(),
      splits: _splitAmounts.entries
          .map(
            (e) => ExpenseSplit(
              userId: e.key,
              amount: e.value,
              splitType: _isSplitEqually ? SplitType.equal : SplitType.exact,
            ),
          )
          .toList(),
    );

    if (widget.initialExpense != null) {
      context.read<GroupExpensesBloc>().add(
        UpdateGroupExpenseRequested(expense),
      );
    } else {
      context.read<GroupExpensesBloc>().add(AddGroupExpenseRequested(expense));
    }
  }

  void _deleteExpense() async {
    if (widget.initialExpense != null) {
      final confirmed = await AppDialogs.showConfirmation(
        context,
        title: 'Delete Expense?',
        content: 'Are you sure you want to delete this expense?',
        confirmText: 'Delete',
        confirmColor: Theme.of(context).colorScheme.error,
      );
      if (confirmed == true && mounted) {
        context.read<GroupExpensesBloc>().add(
          DeleteGroupExpenseRequested(widget.initialExpense!.id),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BlocListener<GroupExpensesBloc, GroupExpensesState>(
      listener: (context, state) {
        if (state is GroupExpenseOperationSucceeded) {
          Navigator.of(context).pop();
        } else if (state is GroupExpensesOperationFailed) {
          AppDialogs.showErrorDialog(context, state.message);
        }
      },
      child: AppScaffold(
        appBar: AppNavBar(
          title: widget.initialExpense != null ? 'Edit Expense' : 'Add Expense',
          actions: [
            if (widget.initialExpense != null)
              IconButton(
                icon: Icon(Icons.delete, color: kit.colors.error),
                onPressed: _deleteExpense,
              ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<GroupExpensesBloc, GroupExpensesState>(
            builder: (context, state) {
              final isLoading = state is GroupExpensesLoading;

              return SingleChildScrollView(
                padding: kit.spacing.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _titleController,
                      label: 'What was this for?',
                      hint: 'e.g., Dinner, Taxi',
                      readOnly: isLoading,
                    ),
                    kit.spacing.gapLg,
                    AppTextField(
                      controller: _amountController,
                      label: 'Amount (${widget.currency})',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      readOnly: isLoading,
                    ),
                    kit.spacing.gapXl,
                    Text('Paid by', style: kit.typography.title),
                    kit.spacing.gapMd,
                    _buildPayersList(isLoading),
                    kit.spacing.gapXl,
                    Text('Split', style: kit.typography.title),
                    kit.spacing.gapMd,
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text('Equally', style: kit.typography.body),
                            value: true,
                            groupValue: _isSplitEqually,
                            onChanged: isLoading ? null : (val) {
                              setState(() => _isSplitEqually = val!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text('Exact Amounts', style: kit.typography.body),
                            value: false,
                            groupValue: _isSplitEqually,
                            onChanged: isLoading ? null : (val) {
                              setState(() => _isSplitEqually = val!);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (!_isSplitEqually) _buildExactSplitsList(isLoading),
                    kit.spacing.gapXl,
                    AppButton(
                      onPressed: isLoading ? null : _submit,
                      label: widget.initialExpense != null
                          ? 'Save Changes'
                          : 'Save Expense',
                      isLoading: isLoading,
                      isFullWidth: true,
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildPayersList(bool isLoading) {
    final membersState = context.watch<GroupMembersBloc>().state;
    final members = membersState.members;
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    if (members.isEmpty) {
      return const Text('Loading members...');
    }

    return Column(
      children: members.map((member) {
        final isMe = member.userId == currentUserId;
        final name = isMe ? 'You' : member.userId;

        final controller = _getPayerController(member.userId, _payerAmounts[member.userId]);

        return AppListTile(
          title: Text(name),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              controller: controller,
              readOnly: isLoading,
              onChanged: (val) {
                final amt = double.tryParse(val) ?? 0.0;
                setState(() {
                  if (amt > 0) {
                    _payerAmounts[member.userId] = amt;
                  } else {
                    _payerAmounts.remove(member.userId);
                  }
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExactSplitsList(bool isLoading) {
    final membersState = context.watch<GroupMembersBloc>().state;
    final members = membersState.members;
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    return Column(
      children: members.map((member) {
        final isMe = member.userId == currentUserId;
        final name = isMe ? 'You' : member.userId;

        final controller = _getSplitController(member.userId, _splitAmounts[member.userId]);

        return AppListTile(
          title: Text(name),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              controller: controller,
              readOnly: isLoading,
              onChanged: (val) {
                final amt = double.tryParse(val) ?? 0.0;
                setState(() {
                  if (amt > 0) {
                    _splitAmounts[member.userId] = amt;
                  } else {
                    _splitAmounts.remove(member.userId);
                  }
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
