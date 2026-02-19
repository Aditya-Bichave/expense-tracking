import 'package:expense_tracker/core/error/failure.dart';

class SyncFailure extends Failure {
  const SyncFailure([String? message]) : super(message ?? 'Sync failed');
}

class OutboxFailure extends Failure {
  const OutboxFailure([String? message])
    : super(message ?? 'Outbox operation failed');
}
