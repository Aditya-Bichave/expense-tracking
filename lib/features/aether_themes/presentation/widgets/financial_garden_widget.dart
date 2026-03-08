import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class FinancialGardenWidget extends StatelessWidget {
  const FinancialGardenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Financial Garden Dashboard\n(Coming Soon!)',
        textAlign: TextAlign.center,
        style: BridgeTextStyle(fontSize: 18, color: Color(0xFF388E3C)),
      ),
    );
  }
}
