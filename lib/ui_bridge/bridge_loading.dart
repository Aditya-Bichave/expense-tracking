import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_skeleton.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_empty_state.dart';

/// Bridge adapter for loading indicators.
class BridgeLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const BridgeLoadingIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    // AppLoadingIndicator expects double (not double?) for size.
    // Providing default size 24.0 if null, assuming standard small size.
    return AppLoadingIndicator(size: size ?? 24.0, color: color);
  }
}

/// Bridge adapter for skeletons.
class BridgeSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const BridgeSkeleton({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Bridge adapter for empty states.
class BridgeEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const BridgeEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(title: title, subtitle: subtitle, icon: icon);
  }
}
