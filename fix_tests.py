import re
import os

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # The actual exception in the log: `Exception: type 'Null' is not a subtype of type 'Future<void>'`
    #   MockOutboxRepository.markAsFailed (file:///app/test/core/sync/sync_service_test.dart:15:7)
    #   SyncService.processOutbox (package:expense_tracker/core/sync/sync_service.dart:223:35)

    if 'sync_service_test.dart' in filepath:
        if 'mockOutboxRepository.markAsFailed' not in content:
            content = content.replace(
                "when(\n        () => mockOutboxRepository.markAsSent(any()),\n      ).thenAnswer((_) async {});",
                "when(\n        () => mockOutboxRepository.markAsSent(any()),\n      ).thenAnswer((_) async {});\n      when(() => mockOutboxRepository.markAsFailed(any(), any())).thenAnswer((_) async {});"
            )

        with open(filepath, 'w') as f:
            f.write(content)

process_file('test/core/sync/sync_service_test.dart')
