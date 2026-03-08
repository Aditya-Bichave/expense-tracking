import re

with open('lib/features/groups/data/repositories/groups_repository_impl.dart', 'r') as f:
    content = f.read()

# Replace unawaited block
old_block = """        unawaited(
          _syncService.processOutbox().catchError((e, s) {
            log.severe("Failed to process outbox in background: $e\\n$s");
          }),
        );"""

new_block = """        _syncService.processOutbox().catchError((e, s) {
          log.severe("Failed to process outbox in background: $e\\n$s");
        });"""

content = content.replace(old_block, new_block)

with open('lib/features/groups/data/repositories/groups_repository_impl.dart', 'w') as f:
    f.write(content)
