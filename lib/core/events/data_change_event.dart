enum DataChangeType {
  expense,
  income,
  account,
  category,
  budget,
  goal,
  goalContribution, // Added
  transaction,
  recurringRule,
  group,
  groupExpense,
  settings, // Added
  system, // Added
}

enum DataChangeReason {
  localCreate,
  localUpdate,
  localDelete,
  remoteUpdate,
  sync,
  added, // Added
  updated, // Added
  deleted, // Added
  reset, // Added
}

class DataChangedEvent {
  final DataChangeType type;
  final DataChangeReason reason;

  const DataChangedEvent({required this.type, required this.reason});
}
