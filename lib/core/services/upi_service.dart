import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Generates and launches the UPI Intent
  static Future<void> launchUpiPayment({
    required BuildContext context,
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
  }) async {
    // 1. Construct the NPCI compliant UPI string
    final String amountStr = amount.toStringAsFixed(2);
    // Encode parameters to handle spaces in names/notes
    final String encodedName = Uri.encodeComponent(payeeName);
    final String encodedNote = Uri.encodeComponent(transactionNote);

    final String upiUrl =
        'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
    final Uri uri = Uri.parse(upiUrl);

    // 2. Launch the URL (Yields control to OS)
    try {
      // LaunchMode.externalApplication is critical for deep links
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (context.mounted) _handleNoUpiApp(context, upiId);
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment Error: ${e.message}')));
      }
    } catch (e) {
      if (context.mounted) _handleNoUpiApp(context, upiId);
    }
  }

  static void _handleNoUpiApp(BuildContext context, String upiId) {
    // Show snackbar letting user copy the UPI ID manually
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No UPI app found. VPA: $upiId'),
        action: SnackBarAction(
          label: 'COPY',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: upiId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('UPI ID copied to clipboard')),
            );
          },
        ),
      ),
    );
  }
}
