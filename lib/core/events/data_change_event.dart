// lib/core/events/data_change_event.dart
enum DataChangeReason { added, updated, deleted }

enum DataChangeType { account, income, expense }

class DataChangedEvent {
  final DataChangeType type;
  final DataChangeReason reason;
  // Optionally add ID of changed item if needed by listeners
  // final String? id;

  const DataChangedEvent({required this.type, required this.reason});

  @override
  String toString() => 'DataChangedEvent(type: $type, reason: $reason)';
}
