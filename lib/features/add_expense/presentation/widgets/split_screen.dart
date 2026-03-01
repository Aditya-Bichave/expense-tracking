import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';

class SplitScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SplitScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddExpenseWizardBloc, AddExpenseWizardState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added securely.')),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else if (state.status == FormStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error adding expense'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Split Expense'),
            actions: [
              if (state.status == FormStatus.processing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: state.isSplitValid
                      ? () => context.read<AddExpenseWizardBloc>().add(
                          const SubmitExpense(),
                        )
                      : null,
                  child: const Text('SAVE'),
                ),
            ],
          ),
          body: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total: ${CurrencyFormatter.format(state.amountTotal, state.currency)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showPayerSelector(context, state),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Paid by ${_getPayerName(state)}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mode Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: SplitMode.values.map((mode) {
                    final isSelected = state.splitMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(mode.displayName),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val)
                            context.read<AddExpenseWizardBloc>().add(
                              SplitModeChanged(mode),
                            );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),

              // Split List
              Expanded(
                child: ListView.separated(
                  itemCount: state.splits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final split = state.splits[index];
                    final member = state.groupMembers.firstWhere(
                      (m) => m.userId == split.userId,
                      orElse: () => GroupMember(
                        id: '',
                        groupId: '',
                        userId: split.userId,
                        role: GroupRole.member,
                        joinedAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                    return _SplitRow(
                      member: member,
                      split: split,
                      mode: state.splitMode,
                      currency: state.currency,
                      onValueChanged: (val) {
                        context.read<AddExpenseWizardBloc>().add(
                          SplitValueChanged(member.userId, val),
                        );
                      },
                    );
                  },
                ),
              ),

              if (!state.isSplitValid)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _getValidationError(state),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getPayerName(AddExpenseWizardState state) {
    if (state.payers.isEmpty) return 'Unknown';
    if (state.payers.length > 1) return 'Multiple People';
    final payerId = state.payers.first.userId;
    if (payerId == state.currentUserId) return 'You';
    final member = state.groupMembers.firstWhere(
      (m) => m.userId == payerId,
      orElse: () => GroupMember(
        id: '',
        groupId: '',
        userId: payerId,
        role: GroupRole.member,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return member.userId; // Ideally Name
  }

  String _getValidationError(AddExpenseWizardState state) {
    if (state.splitMode == SplitMode.percent)
      return "Total percentage must be 100%";
    if (state.splitMode == SplitMode.exact)
      return "Total amount must equal expense total";
    return "Invalid splits";
  }

  void _showPayerSelector(BuildContext context, AddExpenseWizardState state) {
    final bloc = context.read<AddExpenseWizardBloc>();
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Who Paid?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.groupMembers.length,
                  itemBuilder: (ctx, index) {
                    final member = state.groupMembers[index];
                    final isYou = member.userId == state.currentUserId;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          member.userId.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(isYou ? 'You' : member.userId),
                      onTap: () {
                        bloc.add(SinglePayerSelected(member.userId));
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitRow extends StatefulWidget {
  final GroupMember member;
  final SplitModel split;
  final SplitMode mode;
  final String currency;
  final Function(double) onValueChanged;

  const _SplitRow({
    required this.member,
    required this.split,
    required this.mode,
    required this.currency,
    required this.onValueChanged,
  });

  @override
  State<_SplitRow> createState() => _SplitRowState();
}

class _SplitRowState extends State<_SplitRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getInitialValue());
  }

  @override
  void didUpdateWidget(_SplitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _controller.text = _getInitialValue();
    } else if (oldWidget.split.shareValue != widget.split.shareValue) {
      if (double.tryParse(_controller.text) != widget.split.shareValue) {
        // Update only if text doesn't match value (external update)
        _controller.text = _getInitialValue();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitialValue() {
    if (widget.mode == SplitMode.percent || widget.mode == SplitMode.shares) {
      return widget.split.shareValue.toStringAsFixed(
        widget.mode == SplitMode.shares ? 0 : 1,
      );
    }
    if (widget.mode == SplitMode.exact) {
      return widget.split.shareValue.toStringAsFixed(2);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditable = widget.mode != SplitMode.equal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              widget.member.userId.isNotEmpty
                  ? widget.member.userId.substring(0, 1).toUpperCase()
                  : '?',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.member.userId, overflow: TextOverflow.ellipsis),
          ),

          if (isEditable) ...[
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  suffixText: widget.mode == SplitMode.percent
                      ? '%'
                      : (widget.mode == SplitMode.shares ? 'x' : ''),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val);
                  if (d != null) widget.onValueChanged(d);
                },
              ),
            ),
            const SizedBox(width: 12),
          ],

          Text(
            CurrencyFormatter.format(
              widget.split.computedAmount,
              widget.currency,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
