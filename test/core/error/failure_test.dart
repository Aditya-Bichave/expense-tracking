import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/error/failure.dart';

void main() {
  test('ServerFailure supports equality', () {
    expect(const ServerFailure('error'), equals(const ServerFailure('error')));
  });
  test('CacheFailure supports equality', () {
    expect(const CacheFailure('error'), equals(const CacheFailure('error')));
  });
}
