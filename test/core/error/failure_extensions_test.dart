import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/error/failure_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureMessage extension', () {
    test('includes context and database prefix for CacheFailure', () {
      const failure = CacheFailure('DB issue');
      final message = failure.toDisplayMessage(context: 'Load failed');
      expect(message, 'Load failed: Database Error: DB issue');
    });

    test('returns validation message directly', () {
      const failure = ValidationFailure('Invalid input');
      expect(failure.toDisplayMessage(), 'Invalid input');
    });

    test('returns unexpected message', () {
      const failure = UnexpectedFailure();
      expect(
        failure.toDisplayMessage(),
        'An unexpected error occurred. Please try again.',
      );
    });

    test('returns unknown message when empty', () {
      const failure = _FailureStub('');
      expect(failure.toDisplayMessage(), 'An unknown error occurred.');
    });
  });
}

class _FailureStub extends Failure {
  const _FailureStub(super.message);
}
