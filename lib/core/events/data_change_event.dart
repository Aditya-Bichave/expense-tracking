enum DataChangeReason {
  added,
  updated,
  deleted,
  reset,
  localChange,
  remoteSync,
  clearData,
}

enum DataChangeType {
  account,
  accountUpdated,
  accountDeleted,
  income,
  expense,
  settings,
  category,
  goal,
  goalContribution,
  budget,
  recurringRule,
  system,
  initialLoad,
  settlement,
  transactionAdded,
  transactionUpdated,
  transactionDeleted,
  categoryAdded,
  categoryUpdated,
  categoryDeleted,
  budgetAdded,
  budgetUpdated,
  budgetDeleted,
  goalAdded,
  goalUpdated,
  goalDeleted,
  settingsUpdated,
  groupExpense, // Added to be safe if SyncService maps it here
  groupMember,
  group,
  invite,
}

class DataChangedEvent {
  final DataChangeType type;
  final DataChangeReason reason;

  const DataChangedEvent({required this.type, required this.reason});

  @override
  String toString() => 'DataChangedEvent(type: $type, reason: $reason)';
}
