import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupInvitationCard extends StatelessWidget {
  final String token;

  const GroupInvitationCard({super.key, required this.token});

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
                          'Join Group',
                          style: kit.typography.headline.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        kit.spacing.gapLg,
                        Text(
                          'Join your friends to plan the ultimate adventure together.',
                          textAlign: TextAlign.center,
                          style: kit.typography.body,
                        ),
                        kit.spacing.gapXxl,
                        BlocBuilder<DeepLinkBloc, DeepLinkState>(
                          builder: (context, state) {
                            return AppButton(
                              onPressed: state is DeepLinkProcessing
                                  ? null
                                  : () {
                                      context.read<DeepLinkBloc>().add(
                                        DeepLinkManualEntry(token),
                                      );
                                    },
                              label: state is DeepLinkProcessing
                                  ? 'Joining...'
                                  : 'Join Group',
                              isFullWidth: true,
                              size: AppButtonSize.large,
                            );
                          },
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
