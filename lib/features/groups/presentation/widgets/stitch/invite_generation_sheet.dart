import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_dropdown.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';

class InviteGenerationSheet extends StatefulWidget {
  final void Function(String role, int expiry, int limit) onGenerate;

  const InviteGenerationSheet({super.key, required this.onGenerate});

  @override
  State<InviteGenerationSheet> createState() => _InviteGenerationSheetState();
}

class _InviteGenerationSheetState extends State<InviteGenerationSheet> {
  String _role = 'member';
  int _expiry = 7;
  int _limit = 0;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: kit.spacing.lg,
        right: kit.spacing.lg,
        top: kit.spacing.lg,
      ),
      decoration: BridgeDecoration(
        color: kit.colors.surface,
        borderRadius: kit.radii.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invite Members', style: kit.typography.title),
          kit.spacing.gapMd,
          AppDropdown<String>(
            label: 'Role',
            value: _role,
            items: [
              DropdownMenuItem(
                value: 'member',
                child: Text('Member', style: kit.typography.body),
              ),
              DropdownMenuItem(
                value: 'viewer',
                child: Text('Viewer', style: kit.typography.body),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _role = val);
            },
          ),
          kit.spacing.gapSm,
          AppDropdown<int>(
            label: 'Expires In',
            value: _expiry,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text('1 Day', style: kit.typography.body),
              ),
              DropdownMenuItem(
                value: 7,
                child: Text('7 Days', style: kit.typography.body),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text('Never', style: kit.typography.body),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _expiry = val);
            },
          ),
          kit.spacing.gapSm,
          AppDropdown<int>(
            label: 'Usage Limit',
            value: _limit,
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text('Unlimited', style: kit.typography.body),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text('Single Use', style: kit.typography.body),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _limit = val);
            },
          ),
          kit.spacing.gapXl,
          AppButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onGenerate(_role, _expiry, _limit);
            },
            label: 'Generate Link',
            isFullWidth: true,
          ),
          kit.spacing.gapLg,
        ],
      ),
    );
  }
}
