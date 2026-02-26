import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

// Foundations
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_surface.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_chip.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_badge.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';

// Typography
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_link_text.dart';

// Inputs
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_search_field.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_dropdown.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_switch.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_segmented_control.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_checkbox.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_date_picker_field.dart';

// Buttons
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';

// Lists
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_group_card.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_stat_tile.dart';

// Feedback
import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_banner.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_tooltip.dart';

// Loading
import 'package:expense_tracker/ui_kit/components/loading/app_skeleton.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_empty_state.dart';

// Charts
import 'package:expense_tracker/ui_kit/components/charts/app_chart_card.dart';

class UiKitShowcasePage extends StatefulWidget {
  const UiKitShowcasePage({super.key});

  @override
  State<UiKitShowcasePage> createState() => _UiKitShowcasePageState();
}

class _UiKitShowcasePageState extends State<UiKitShowcasePage> {
  bool _switchVal = false;
  bool? _checkVal = false;
  int? _segmentVal = 0;
  DateTime? _dateVal;
  String? _dropdownVal;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      appBar: AppNavBar(
        title: 'UI Kit Showcase',
        actions: [
          AppIconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {},
            tooltip: 'Change Theme (Not impl here)',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: kit.spacing.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Typography', [
                const AppText('Display Large', style: AppTextStyle.display),
                const AppText('Title Medium', style: AppTextStyle.title),
                const AppText('Headline Small', style: AppTextStyle.headline),
                const AppText('Body Regular', style: AppTextStyle.body),
                const AppText('Body Strong', style: AppTextStyle.bodyStrong),
                const AppText('Caption Text', style: AppTextStyle.caption),
                const AppText('OVERLINE TEXT', style: AppTextStyle.overline),
                kit.spacing.gapMd,
                AppLinkText('This is a link text', onTap: () {}),
              ]),

              _buildSection('Buttons', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(label: 'Primary', onPressed: () {}),
                    AppButton(
                      label: 'Secondary',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Ghost',
                      variant: AppButtonVariant.ghost,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Destructive',
                      variant: AppButtonVariant.destructive,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Loading',
                      isLoading: true,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Disabled',
                      disabled: true,
                      onPressed: () {},
                    ),
                    const AppFAB(
                      icon: Icon(Icons.add),
                      label: 'Extended',
                      extended: true,
                    ),
                    const AppFAB(icon: Icon(Icons.add)),
                  ],
                ),
              ]),

              _buildSection('Inputs', [
                const AppTextField(label: 'Text Field', hint: 'Enter text'),
                kit.spacing.gapMd,
                const AppTextField(
                  label: 'Error Field',
                  errorText: 'Something went wrong',
                ),
                kit.spacing.gapMd,
                const AppSearchField(),
                kit.spacing.gapMd,
                AppDropdown<String>(
                  label: 'Dropdown',
                  value: _dropdownVal,
                  hint: 'Select option',
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Option 1')),
                    DropdownMenuItem(value: '2', child: Text('Option 2')),
                  ],
                  onChanged: (v) => setState(() => _dropdownVal = v),
                ),
                kit.spacing.gapMd,
                AppDatePickerField(
                  selectedDate: _dateVal,
                  onDateSelected: (d) => setState(() => _dateVal = d),
                  label: 'Date Picker',
                ),
                kit.spacing.gapMd,
                Row(
                  children: [
                    AppSwitch(
                      value: _switchVal,
                      onChanged: (v) => setState(() => _switchVal = v),
                    ),
                    kit.spacing.gapMd,
                    AppCheckbox(
                      value: _checkVal ?? false,
                      onChanged: (v) => setState(() => _checkVal = v),
                    ),
                  ],
                ),
                kit.spacing.gapMd,
                AppSegmentedControl<int>(
                  groupValue: _segmentVal,
                  onValueChanged: (v) => setState(() => _segmentVal = v),
                  children: const {
                    0: Text('Segment 1'),
                    1: Text('Segment 2'),
                    2: Text('Segment 3'),
                  },
                ),
              ]),

              _buildSection('Lists & Cards', [
                AppCard(
                  child: Column(
                    children: [
                      AppListTile(
                        title: const Text('List Tile Title'),
                        subtitle: const Text('Subtitle goes here'),
                        leading: const Icon(Icons.person),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const AppDivider(),
                      AppListTile(
                        title: const Text('Selected Tile'),
                        selected: true,
                        leading: const AppAvatar(initials: 'AB'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                kit.spacing.gapMd,
                AppGroupCard(
                  title: 'Group Card',
                  children: [
                    const AppStatTile(
                      label: 'Total Spent',
                      value: '\$1,234.56',
                      icon: Icon(Icons.attach_money),
                    ),
                    const AppStatTile(
                      label: 'Budget Left',
                      value: '\$456.00',
                      icon: Icon(Icons.pie_chart),
                    ),
                  ],
                ),
              ]),

              _buildSection('Feedback', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Show Dialog',
                      onPressed: () => AppDialog.show(
                        context: context,
                        title: 'Confirm Action',
                        content: 'Are you sure you want to do this?',
                        confirmLabel: 'Yes',
                        cancelLabel: 'No',
                        onConfirm: () => Navigator.pop(context),
                      ),
                    ),
                    AppButton(
                      label: 'Show Bottom Sheet',
                      onPressed: () => AppBottomSheet.show(
                        context: context,
                        title: 'Bottom Sheet',
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          child: const Text('Sheet Content'),
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Show Toast',
                      onPressed: () => AppToast.show(
                        context,
                        'Operation successful!',
                        type: AppToastType.success,
                      ),
                    ),
                  ],
                ),
                kit.spacing.gapMd,
                const AppBanner(
                  message: 'This is an info banner',
                  type: AppBannerType.info,
                ),
                kit.spacing.gapSm,
                const AppBanner(
                  message: 'This is a warning banner',
                  type: AppBannerType.warning,
                ),
              ]),

              _buildSection('Loading & Empty', [
                const Row(
                  children: [
                    AppLoadingIndicator(),
                    SizedBox(width: 16),
                    AppSkeleton(width: 100, height: 20),
                  ],
                ),
                kit.spacing.gapMd,
                const AppEmptyState(
                  title: 'No Data',
                  subtitle: 'Try adding something new',
                  icon: Icons.inbox,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return AppSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
