import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';

class GroupDetailHeader extends StatelessWidget {
  const GroupDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppCard(
      padding: kit.spacing.allXl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GROUP SPEND',
                style: kit.typography.overline.copyWith(
                  color: kit.colors.textSecondary,
                ),
              ),
              kit.spacing.gapXs,
              Text(
                '\$2,450.00',
                style: kit.typography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'You are owed',
                style: kit.typography.caption.copyWith(
                  color: kit.colors.textSecondary,
                ),
              ),
              kit.spacing.gapXs,
              Text(
                '\$120.00',
                style: kit.typography.title.copyWith(
                  color: kit.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              kit.spacing.gapSm,
              AppButton(
                onPressed: () {},
                label: 'Settle Up',
                size: AppButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
