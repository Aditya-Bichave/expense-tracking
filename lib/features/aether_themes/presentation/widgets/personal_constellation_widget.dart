import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';

class PersonalConstellationWidget extends StatelessWidget {
  const PersonalConstellationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Personal Constellation Dashboard\n(Coming Soon!)',
        textAlign: TextAlign.center,
        style: BridgeTextStyle(fontSize: 18, color: Colors.blueAccent),
      ),
    );
  }
}
