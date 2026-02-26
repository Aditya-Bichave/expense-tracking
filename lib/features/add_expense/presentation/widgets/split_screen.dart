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
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_segmented_control.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

class SplitScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SplitScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BlocConsumer<AddExpenseWizardBloc, AddExpenseWizardState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added securely.')),
          );
          Navigator.of(context).pop();
        } else if (state.status == FormStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error adding expense'),
              backgroundColor: kit.colors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return AppScaffold(
          appBar: AppNavBar(
            leading: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              color: kit.colors.textPrimary,
            ),
            title: 'Split Expense',
            actions: [
              if (state.status == FormStatus.processing)
                Center(
                  child: Padding(
                    padding: kit.spacing.hMd,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(kit.colors.primary),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: kit.spacing.hSm,
                  child: AppButton(
                    variant: UiVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: state.isSplitValid
                        ? () => context.read<AddExpenseWizardBloc>().add(
                              const SubmitExpense(),
                            )
                        : null,
                    label: 'SAVE',
                    disabled: !state.isSplitValid,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Header
              Padding(
                padding: kit.spacing.allMd,
                child: Column(
                  children: [
                    Text(
                      'Total: ${CurrencyFormatter.format(state.amountTotal, state.currency)}',
                      style: kit.typography.title,
                    ),
                    kit.spacing.gapSm,
                    GestureDetector(
                      onTap: () => _showPayerSelector(context, state),
                      child: Padding(
                        padding: kit.spacing.allSm,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Paid by ${_getPayerName(state)}',
                              style: kit.typography.bodyStrong.copyWith(
                                color: kit.colors.primary,
                              ),
                            ),
                            kit.spacing.wXxs,
                            Icon(
                              Icons.arrow_drop_down,
                              color: kit.colors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mode Selector
              Padding(
                padding: kit.spacing.hMd,
                child: AppSegmentedControl<SplitMode>(
                  groupValue: state.splitMode,
                  onValueChanged: (mode) {
                    if (mode != null) {
                      context
                          .read<AddExpenseWizardBloc>()
                          .add(SplitModeChanged(mode));
                    }
                  },
                  children: {
                    for (var mode in SplitMode.values)
                      mode: Padding(
                        padding: kit.spacing.vSm,
                        child: Text(
                          mode.displayName,
                          style: kit.typography.labelMedium,
                        ),
                      ),
                  },
                ),
              ),
              kit.spacing.gapMd,
              const AppDivider(),

              // Split List
              Expanded(
                child: ListView.separated(
                  itemCount: state.splits.length,
                  separatorBuilder: (_, __) => const AppDivider(),
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
                  padding: kit.spacing.allMd,
                  child: Text(
                    _getValidationError(state),
                    style: kit.typography.caption.copyWith(
                      color: kit.colors.error,
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
    if (state.splitMode == SplitMode.percent) {
      return "Total percentage must be 100%";
    }
    if (state.splitMode == SplitMode.exact) {
      return "Total amount must equal expense total";
    }
    return "Invalid splits";
  }

  void _showPayerSelector(BuildContext context, AddExpenseWizardState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(
        title: 'Who Paid?',
        child: SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: state.groupMembers.length,
            itemBuilder: (ctx, index) {
              final member = state.groupMembers[index];
              final isYou = member.userId == state.currentUserId;
              return AppListTile(
                leading: AppAvatar(
                  initials: member.userId.substring(0, 1).toUpperCase(),
                  size: 32,
                ),
                title: Text(isYou ? 'You' : member.userId),
                onTap: () {
                  context.read<AddExpenseWizardBloc>().add(
                        SinglePayerSelected(member.userId),
                      );
                  Navigator.pop(ctx);
                },
              );
            },
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
    final kit = context.kit;
    final bool isEditable = widget.mode != SplitMode.equal;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: kit.spacing.sm, // vSm is sm
        horizontal: kit.spacing.md,
      ),
      child: Row(
        children: [
          AppAvatar(
            initials: widget.member.userId.isNotEmpty
                ? widget.member.userId.substring(0, 1).toUpperCase()
                : '?',
            size: 32,
          ),
          kit.spacing.wMd,
          Expanded(
            child: Text(
              widget.member.userId,
              overflow: TextOverflow.ellipsis,
              style: kit.typography.body,
            ),
          ),
          if (isEditable) ...[
            SizedBox(
              width: 80,
              child: AppTextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixIcon: widget.mode == SplitMode.percent
                    ? Padding(
                        padding: kit.spacing.allSm,
                        child: Text(
                          '%',
                          style: kit.typography.bodySmall,
                        ),
                      )
                    : (widget.mode == SplitMode.shares
                        ? Padding(
                            padding: kit.spacing.allSm,
                            child: Text(
                              'x',
                              style: kit.typography.bodySmall,
                            ),
                          )
                        : null),
                onChanged: (val) {
                  final d = double.tryParse(val);
                  if (d != null) widget.onValueChanged(d);
                },
              ),
            ),
            kit.spacing.wMd,
          ],
          Text(
            CurrencyFormatter.format(
              widget.split.computedAmount,
              widget.currency,
            ),
            style: kit.typography.bodyStrong,
          ),
        ],
      ),
    );
  }
}
