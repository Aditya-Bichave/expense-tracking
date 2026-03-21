sed -i 's|final outboxFailedItems = await _outboxRepository.getFailedItems();||g' lib/features/group_expenses/data/repositories/group_expenses_repository_impl.dart
sed -i 's|..addAll(outboxFailedItems.map((e) => e.id));||g' lib/features/group_expenses/data/repositories/group_expenses_repository_impl.dart
