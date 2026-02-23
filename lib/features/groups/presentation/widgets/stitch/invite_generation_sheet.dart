import 'package:flutter/material.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invite Members', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          AppDropdownFormField<String>(
            labelText: 'Role',
            value: _role,
            items: const [
              DropdownMenuItem(value: 'member', child: Text('Member')),
              DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
            ],
            onChanged: (val) => setState(() => _role = val!),
          ),
          const SizedBox(height: 12),
          AppDropdownFormField<int>(
            labelText: 'Expires In',
            value: _expiry,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 Day')),
              DropdownMenuItem(value: 7, child: Text('7 Days')),
              DropdownMenuItem(value: 0, child: Text('Never')),
            ],
            onChanged: (val) => setState(() => _expiry = val!),
          ),
          const SizedBox(height: 12),
          AppDropdownFormField<int>(
            labelText: 'Usage Limit',
            value: _limit,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Unlimited')),
              DropdownMenuItem(value: 1, child: Text('Single Use')),
            ],
            onChanged: (val) => setState(() => _limit = val!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onGenerate(_role, _expiry, _limit);
            },
            child: const Text('Generate Link'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
