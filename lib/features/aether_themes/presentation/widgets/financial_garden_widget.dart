import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';

class FinancialGardenWidget extends StatelessWidget {
  const FinancialGardenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Financial Garden visual dashboard (Phase 4)
    return const Center(
      child: Text(
        'Financial Garden Dashboard\n(Coming Soon!)',
        textAlign: TextAlign.center,
        style: BridgeTextStyle(fontSize: 18, color: Colors.green),
      ),
    );
  }
}
