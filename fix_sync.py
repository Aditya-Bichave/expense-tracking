import re

with open('lib/core/sync/sync_service.dart', 'r') as f:
    content = f.read()

content = content.replace(
    'unawaited(processOutbox());',
    'processOutbox().catchError((e, s) { log.severe("Error in processOutbox connectivity listener", e, s); });'
)

content = content.replace(
    'unawaited(_ensureGroupExists(serverMember.groupId));',
    '_ensureGroupExists(serverMember.groupId).catchError((e, s) { log.severe("Error ensuring group exists during member realtime sync", e, s); });'
)

with open('lib/core/sync/sync_service.dart', 'w') as f:
    f.write(content)
