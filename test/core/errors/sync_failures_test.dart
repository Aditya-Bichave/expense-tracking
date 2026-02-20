import 'package:expense_tracker/core/errors/sync_failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncFailure supports value equality', () {
    expect(const SyncFailure('error'), const SyncFailure('error'));
    expect(const SyncFailure('error'), isNot(const SyncFailure('other')));
  });

  test('OutboxFailure supports value equality', () {
    expect(const OutboxFailure('error'), const OutboxFailure('error'));
  });
}
