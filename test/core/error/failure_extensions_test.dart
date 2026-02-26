import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/error/failure_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureMessage extension', () {
    test('returns validation message directly', () {
      const failure = ValidationFailure('Invalid input');
      expect(failure.toDisplayMessage(), 'Invalid input');
    });

    test('includes context and database prefix for CacheFailure', () {
      const failure = CacheFailure('Read failed');
      expect(
        failure.toDisplayMessage(context: 'Loading'),
        'Loading: Database Error: Read failed',
      );
    });

    test('returns unexpected message', () {
      const failure = UnexpectedFailure();
      expect(
        failure.toDisplayMessage(),
        'An unexpected error occurred. Please try again.',
      );
    });

    test('returns unknown message when empty', () {
      // Assuming a generic failure with empty message if possible, or mocking
      // But Failure is abstract. Let's create a concrete one.
      final failure = _GenericFailure('');
      expect(failure.toDisplayMessage(), 'An unknown error occurred.');
    });
  });
}

class _GenericFailure extends Failure {
  const _GenericFailure(super.message);
}
