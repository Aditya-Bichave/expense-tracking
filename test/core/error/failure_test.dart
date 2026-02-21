import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/error/failure.dart';

void main() {
  group('Failure', () {
    group('ServerFailure', () {
      test('supports equality with same message', () {
        expect(
          const ServerFailure('error'),
          equals(const ServerFailure('error')),
        );
      });

      test('supports inequality with different messages', () {
        expect(
          const ServerFailure('error1'),
          isNot(equals(const ServerFailure('error2'))),
        );
      });

      test('has default message', () {
        expect(
          const ServerFailure().message,
          'A server error occurred.',
        );
      });

      test('uses custom message when provided', () {
        expect(
          const ServerFailure('Custom error').message,
          'Custom error',
        );
      });
    });

    group('CacheFailure', () {
      test('supports equality with same message', () {
        expect(
          const CacheFailure('error'),
          equals(const CacheFailure('error')),
        );
      });

      test('supports inequality with different messages', () {
        expect(
          const CacheFailure('error1'),
          isNot(equals(const CacheFailure('error2'))),
        );
      });

      test('has default message', () {
        expect(
          const CacheFailure().message,
          'A local data storage error occurred.',
        );
      });

      test('uses custom message when provided', () {
        expect(
          const CacheFailure('Custom cache error').message,
          'Custom cache error',
        );
      });
    });

    group('ValidationFailure', () {
      test('supports equality', () {
        expect(
          const ValidationFailure('validation error'),
          equals(const ValidationFailure('validation error')),
        );
      });

      test('stores message correctly', () {
        expect(
          const ValidationFailure('Invalid input').message,
          'Invalid input',
        );
      });
    });

    group('NetworkFailure', () {
      test('supports equality', () {
        expect(
          const NetworkFailure(),
          equals(const NetworkFailure()),
        );
      });

      test('has default message', () {
        expect(
          const NetworkFailure().message,
          'Please check your network connection.',
        );
      });

      test('uses custom message when provided', () {
        expect(
          const NetworkFailure('No internet').message,
          'No internet',
        );
      });
    });

    group('SettingsFailure', () {
      test('supports equality', () {
        expect(
          const SettingsFailure('settings error'),
          equals(const SettingsFailure('settings error')),
        );
      });

      test('stores message correctly', () {
        expect(
          const SettingsFailure('Failed to save').message,
          'Failed to save',
        );
      });
    });

    group('BackupFailure', () {
      test('supports equality', () {
        expect(
          const BackupFailure('backup error'),
          equals(const BackupFailure('backup error')),
        );
      });
    });

    group('RestoreFailure', () {
      test('supports equality', () {
        expect(
          const RestoreFailure('restore error'),
          equals(const RestoreFailure('restore error')),
        );
      });
    });

    group('ClearDataFailure', () {
      test('supports equality', () {
        expect(
          const ClearDataFailure('clear error'),
          equals(const ClearDataFailure('clear error')),
        );
      });
    });

    group('FileSystemFailure', () {
      test('supports equality', () {
        expect(
          const FileSystemFailure('fs error'),
          equals(const FileSystemFailure('fs error')),
        );
      });
    });

    group('AuthenticationFailure', () {
      test('supports equality', () {
        expect(
          const AuthenticationFailure('auth error'),
          equals(const AuthenticationFailure('auth error')),
        );
      });

      test('stores message correctly', () {
        expect(
          const AuthenticationFailure('Invalid credentials').message,
          'Invalid credentials',
        );
      });
    });

    group('UnexpectedFailure', () {
      test('supports equality', () {
        expect(
          const UnexpectedFailure(),
          equals(const UnexpectedFailure()),
        );
      });

      test('has default message', () {
        expect(
          const UnexpectedFailure().message,
          'An unexpected error occurred.',
        );
      });

      test('uses custom message when provided', () {
        expect(
          const UnexpectedFailure('Something went wrong').message,
          'Something went wrong',
        );
      });
    });

    group('NotFoundFailure', () {
      test('supports equality', () {
        expect(
          const NotFoundFailure('not found'),
          equals(const NotFoundFailure('not found')),
        );
      });

      test('stores message correctly', () {
        expect(
          const NotFoundFailure('Resource not found').message,
          'Resource not found',
        );
      });
    });

    test('different failure types are not equal', () {
      expect(
        const ServerFailure('error'),
        isNot(equals(const CacheFailure('error'))),
      );
      expect(
        const ValidationFailure('error'),
        isNot(equals(const NetworkFailure('error'))),
      );
    });

    test('all failures extend Failure base class', () {
      expect(const ServerFailure(), isA<Failure>());
      expect(const CacheFailure(), isA<Failure>());
      expect(const ValidationFailure(''), isA<Failure>());
      expect(const NetworkFailure(), isA<Failure>());
      expect(const SettingsFailure(''), isA<Failure>());
      expect(const BackupFailure(''), isA<Failure>());
      expect(const RestoreFailure(''), isA<Failure>());
      expect(const ClearDataFailure(''), isA<Failure>());
      expect(const FileSystemFailure(''), isA<Failure>());
      expect(const AuthenticationFailure(''), isA<Failure>());
      expect(const UnexpectedFailure(), isA<Failure>());
      expect(const NotFoundFailure(''), isA<Failure>());
    });
  });
}