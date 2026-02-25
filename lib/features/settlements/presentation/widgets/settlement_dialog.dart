import 'package:flutter/material.dart';
import 'package:expense_tracker/core/services/upi_service.dart';

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
    return AlertDialog(
      title: Text('Settle with $receiverName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$amount $currency',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (receiverUpiId != null && receiverUpiId!.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: () {
                UpiService.launchUpiPayment(
                  context: context,
                  upiId: receiverUpiId!,
                  payeeName: receiverName,
                  amount: amount,
                  transactionNote: 'Settlement via Spend Savvy',
                ).then((_) {
                  // Prompt user after return
                  if (context.mounted) {
                    _showConfirmationDialog(context);
                  }
                });
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay via UPI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'VPA: $receiverUpiId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          const Text('Or mark as paid manually if you used cash/other.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onSettled();
            Navigator.pop(context);
          },
          child: const Text('Mark as Paid'),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful?'),
        content: const Text('Did the UPI transaction complete successfully?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              onSettled(); // Trigger settlement logic
              Navigator.pop(context); // Close parent settlement dialog
            },
            child: const Text('Yes, Record Settlement'),
          ),
        ],
      ),
    );
  }
}
