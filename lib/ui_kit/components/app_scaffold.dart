import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Scaffold(
      backgroundColor: backgroundColor ?? kit.colors.background,
      appBar: appBar,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
