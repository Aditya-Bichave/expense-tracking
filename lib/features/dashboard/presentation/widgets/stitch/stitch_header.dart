// lib/features/dashboard/presentation/widgets/stitch/stitch_header.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';

class StitchHeader extends StatelessWidget {
  final String userName;
  final String userImageUrl;

  const StitchHeader({
    super.key,
    this.userName = "Alex Rivera",
    this.userImageUrl =
        "https://lh3.googleusercontent.com/aida-public/AB6AXuAVZKsr4cm8B7IQAm8clilGH2mCQ1opuZuF6sbpsEOgRSRdP3pYugyHgAf8YxC-u79Nbn-oiNWX7wZD4Zy98pMXG-ClQgdKvJUBVOAe-DgERpJeQWgsfA2kUj8csuInJ-eWXVX2EO6NxZfs6yFGDRWoFzfC9rjQ6HLAjNO9Z_OVpY1xExFrk-eY6y8UHCAtXmhSlbE3N7itGR6Kef4MBOEfHId1AidIrDwvbSIggBOsConEKwFWR8ty84_prL_sSgtIFib80smQXg",
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kit.spacing.lg,
        vertical: kit.spacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BridgeDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kit.colors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: context.space.allXxs,
                  child: ClipOval(
                    child: Image.network(
                      userImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: kit.colors.primaryContainer),
                    ),
                  ),
                ),
              ),
              kit.spacing.gapMd,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BridgeText(
                    'Welcome back',
                    style: kit.typography.labelSmall.copyWith(
                      color: kit.colors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  BridgeText(
                    userName,
                    style: kit.typography.title.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BridgeDecoration(
                  shape: BoxShape.circle,
                  color: kit.colors.surfaceContainer.withOpacity(0.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: kit.colors.textSecondary,
                  ),
                  onPressed: () {},
                  padding: const EdgeInsets.only(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BridgeDecoration(
                    color: kit.colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: kit.colors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
