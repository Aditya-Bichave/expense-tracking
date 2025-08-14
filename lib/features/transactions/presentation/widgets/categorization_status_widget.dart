import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart';

class CategorizationStatusWidget extends StatelessWidget {
  final TransactionEntity transaction;
  final void Function(TransactionEntity tx, Category category)?
  onUserCategorized;
  final void Function(TransactionEntity tx)? onChangeCategoryRequest;

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

    switch (transaction.status) {
      case CategorizationStatus.needsReview:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.0,
          runSpacing: 4.0,
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: warningColor),
            Text(
              'Suggest: ${transaction.category?.name ?? "?"}',
              style: textStyleSmall.copyWith(
                color: warningColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                icon: Icon(Icons.check, size: 16, color: successColor),
                label: Text(
                  'Confirm',
                  style: textStyleSmall.copyWith(color: successColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: buttonPadding,
                  minimumSize: buttonMinSize,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: successColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  log.info(
                    '[CategorizationStatus] Suggestion confirmed for ${transaction.id}',
                  );
                  if (transaction.category != null &&
                      onUserCategorized != null) {
                    onUserCategorized!(transaction, transaction.category!);
                  }
                },
              ),
            ),
            SizedBox(
              height: 28,
              child: TextButton.icon(
                icon: Icon(Icons.edit_outlined, size: 16, color: primaryColor),
                label: Text(
                  'Change',
                  style: textStyleSmall.copyWith(color: primaryColor),
                ),
                style: TextButton.styleFrom(
                  padding: buttonPadding,
                  minimumSize: buttonMinSize,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  log.info(
                    '[CategorizationStatus] Change requested for suggested ${transaction.id}',
                  );
                  onChangeCategoryRequest?.call(transaction);
                },
              ),
            ),
          ],
        );
      case CategorizationStatus.uncategorized:
        return TextButton.icon(
          icon: Icon(Icons.label_off_outlined, size: 16, color: errorColor),
          label: Text(
            'Categorize',
            style: textStyleSmall.copyWith(color: errorColor),
          ),
          style: TextButton.styleFrom(
            padding: buttonPadding,
            minimumSize: buttonMinSize,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            log.info(
              '[CategorizationStatus] Change requested for uncategorized ${transaction.id}',
            );
            onChangeCategoryRequest?.call(transaction);
          },
        );
      case CategorizationStatus.categorized:
        return InkWell(
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
}
