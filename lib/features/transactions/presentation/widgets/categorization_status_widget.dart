import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart';

class CategorizationStatusWidget extends StatelessWidget {
  final Transaction transaction;
  final void Function(Transaction tx, Category category)?
      onUserCategorized;
  final void Function(Transaction tx)? onChangeCategoryRequest;

  const CategorizationStatusWidget({
    super.key,
    required this.transaction,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleSmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color primaryColor = theme.colorScheme.primary;
    final Color errorColor = theme.colorScheme.error;
    final Color successColor = Colors.green.shade600;
    final Color warningColor = Colors.orange.shade800;
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: 6.0,
      vertical: 2.0,
    );
    const Size buttonMinSize = Size(28, 28);

    return InkWell(
      key: const ValueKey('inkwell_categorization_change_categorized'),
      onTap: () {
        log.info(
          '[CategorizationStatus] Change requested for categorized ${transaction.id}',
        );
        onChangeCategoryRequest?.call(transaction);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              transaction.category?.name ?? Category.uncategorized.name,
              style: textStyleSmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
