// lib/core/events/data_change_event.dart

// Describes the type of data operation
enum DataChangeReason { added, updated, deleted }

// Describes the type of data affected
enum DataChangeType {
  account,
  income,
  expense,
  settings,
  category
} // Added settings

class DataChangedEvent {
  final DataChangeType type;
  final DataChangeReason reason;
  // Optionally add ID of changed item if needed by specific listeners
  // final String? id;

  const DataChangedEvent({required this.type, required this.reason});

  @override
  String toString() => 'DataChangedEvent(type: $type, reason: $reason)';
}
