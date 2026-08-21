import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TrashBinPage extends StatelessWidget {
  const TrashBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrashBinBloc>(
      lazy: false,
      create: (_) => sl<TrashBinBloc>()..add(LoadTrash()),
      child: const TrashBinView(),
    );
  }
}

class TrashBinView extends StatelessWidget {
  const TrashBinView({super.key});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BridgeScaffold(
      appBar: AppBar(title: const Text('Trash Bin')),
      body: SafeArea(
        child: BlocBuilder<TrashBinBloc, TrashBinState>(
          builder: (context, state) {
            if (state is TrashBinLoading || state is TrashBinInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TrashBinError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: kit.colors.error),
                ),
              );
            }

            if (state is TrashBinEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 64,
                        color: kit.colors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nothing in the trash',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kit.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Items in the trash are removed automatically after 30 days.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: kit.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is TrashBinLoaded) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: state.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  final isExpense = item.type == TrashItemType.expense;
                  final timeAgo = _formatTimeAgo(item.deletedAt);

                  return AppListTile(
                    leading: CircleAvatar(
                      backgroundColor: isExpense
                          ? kit.colors.error.withOpacity(0.1)
                          : kit.colors.success.withOpacity(0.1),
                      child: Icon(
                        isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isExpense
                            ? kit.colors.error
                            : kit.colors.success,
                      ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Deleted $timeAgo • ${isExpense ? '-' : '+'}\$${item.amount.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'restore') {
                          context.read<TrashBinBloc>().add(
                            RestoreItem(id: item.id, type: item.type),
                          );
                        } else if (value == 'purge') {
                          _confirmPurge(context, item);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Text('Restore'),
                        ),
                        const PopupMenuItem(
                          value: 'purge',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(dateTime);
  }

  void _confirmPurge(BuildContext context, TrashItem item) {
    final bloc = context.read<TrashBinBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
        ),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(PurgeItem(id: item.id, type: item.type));
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
