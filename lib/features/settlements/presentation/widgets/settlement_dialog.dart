import 'package:flutter/material.dart';
import 'package:expense_tracker/core/services/upi_service.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';

class SettlementDialog extends StatelessWidget {
  final String receiverName;
  final String? receiverUpiId;
  final double amount;
  final String currency;
  final VoidCallback onSettled;

  const SettlementDialog({
    super.key,
    required this.receiverName,
    this.receiverUpiId,
    required this.amount,
    required this.currency,
    required this.onSettled,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppDialog(
      title: 'Settle with $receiverName',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$amount $currency', style: kit.typography.display),
          kit.spacing.gapLg,
          if (receiverUpiId != null && receiverUpiId!.isNotEmpty) ...[
            AppButton(
              onPressed: () {
                UpiService.launchUpiPayment(
                  context: context,
                  upiId: receiverUpiId!,
                  payeeName: receiverName,
                  amount: amount,
                  transactionNote: 'Settlement via Spend Savvy',
                ).then((_) {
                  if (context.mounted) {
                    _showConfirmationDialog(context);
                  }
                });
              },
              icon: const Icon(Icons.payment),
              label: 'Pay via UPI',
              variant: AppButtonVariant.primary,
            ),
            kit.spacing.gapSm,
            Text(
              'VPA: $receiverUpiId',
              style: kit.typography.caption.copyWith(
                color: kit.colors.textSecondary,
              ),
            ),
            kit.spacing.gapLg,
          ],
          Text(
            'Or mark as paid manually if you used cash/other.',
            style: kit.typography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      confirmLabel: 'Mark as Paid',
      onConfirm: () {
        onSettled();
        Navigator.pop(context);
      },
      cancelLabel: 'Cancel',
      onCancel: () => Navigator.pop(context),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      title: 'Payment Successful?',
      content: 'Did the UPI transaction complete successfully?',
      confirmLabel: 'Yes, Record Settlement',
      onConfirm: () {
        Navigator.pop(context); // Close confirmation
        onSettled(); // Trigger settlement logic
        Navigator.pop(context); // Close parent settlement dialog
      },
      cancelLabel: 'Not yet',
      onCancel: () => Navigator.pop(context),
    );
  }
}
