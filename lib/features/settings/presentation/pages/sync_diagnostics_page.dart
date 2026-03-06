// coverage:ignore-file
// ignore_for_file: coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'dart:convert';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';

class SyncDiagnosticsPage extends StatefulWidget {
  const SyncDiagnosticsPage({super.key});

  @override
  State<SyncDiagnosticsPage> createState() => _SyncDiagnosticsPageState();
}

class _SyncDiagnosticsPageState extends State<SyncDiagnosticsPage> {
  final _deadLetterRepository = sl<DeadLetterRepository>();
  final _outboxRepository = sl<OutboxRepository>();
  final _syncService = sl<SyncService>();

  List<DeadLetterModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = _deadLetterRepository.getItems();
    });
  }

  Future<void> _retryItem(DeadLetterModel item) async {
    // Convert back to SyncMutationModel and reset retries
    final mutation = item.toSyncMutation();
    await _outboxRepository.add(mutation);

    // Remove from dead letters
    await _deadLetterRepository.deleteItem(item);

    _loadItems();

    // Trigger sync
    _syncService.processOutbox();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item queued for retry')));
    }
  }

  Future<void> _discardItem(DeadLetterModel item) async {
    await _deadLetterRepository.deleteItem(item);
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item discarded')));
    }
  }

  void _showPayload(DeadLetterModel item) {
    showDialog(
      context: context,
      builder: (context) {
        final payloadStr = const JsonEncoder.withIndent(
          '  ',
        ).convert(item.payload);
        return AlertDialog(
          title: const Text('Payload Details'),
          content: SingleChildScrollView(child: Text(payloadStr)),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payloadStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payload copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppNavBar(title: 'Sync Diagnostics'),
      body: _items.isEmpty
          ? const Center(child: Text('No failed sync items.'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table: ${item.table}',
                          style: context.kit.typography.bodyLarge,
                        ),
                        Text('Operation: ${item.operation.name}'),
                        Text('Failed at: ${item.failedAt}'),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${item.lastError}',
                          style: TextStyle(color: context.kit.colors.error),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _showPayload(item),
                              child: const Text('Payload'),
                            ),
                            TextButton(
                              onPressed: () => _discardItem(item),
                              child: const Text('Discard'),
                            ),
                            AppButton(
                              label: 'Retry',
                              onPressed: () => _retryItem(item),
                              variant: UiVariant.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
