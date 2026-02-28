import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';

class GroupInvitationCard extends StatelessWidget {
  const GroupInvitationBridgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Center(
      child: Padding(
        padding: kit.spacing.allXl,
        child: ClipRRect(
          borderRadius: kit.radii.large,
          child: Stack(
            children: [
              // Background Image Mock
              Container(
                height: 500,
                width: double.infinity,
                color: kit.colors.surfaceContainer,
              ),
              // Glass Overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: kit.colors.surface.withOpacity(0.6),
                    padding: kit.spacing.allXxl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "YOU'RE INVITED",
                          style: kit.typography.overline.copyWith(
                            color: kit.colors.primary,
                            letterSpacing: 2.0,
                          ),
                        ),
                        kit.spacing.gapLg,
                        Text(
                          'Europe Tour',
                          style: kit.typography.headline.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        kit.spacing.gapLg,
                        Text(
                          'Join your friends to plan the ultimate summer adventure across the continent.',
                          textAlign: TextAlign.center,
                          style: kit.typography.body,
                        ),
                        kit.spacing.gapXxl,
                        AppButton(
                          onPressed: () {},
                          label: 'Join Group',
                          isFullWidth: true,
                          size: AppButtonSize.large,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
