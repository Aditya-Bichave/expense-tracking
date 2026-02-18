import 'package:expense_tracker/core/error/failure.dart';

class SyncFailure extends Failure {
  const SyncFailure([String message = "Synchronization failed."])
    : super(message);
}
