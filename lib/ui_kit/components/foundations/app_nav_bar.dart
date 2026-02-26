import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? titleWidget;

  const AppNavBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: kit.typography.title,
                )
              : null),
      actions: actions,
      iconTheme: IconThemeData(
        color: kit.colors.textPrimary,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
