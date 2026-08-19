import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unwraps the success side of an [Either], failing the test with the failure
/// if it turned out to be a `Left`.
T rightOf<T>(Either<Failure, T> either) =>
    either.fold((l) => fail('expected a success, got $l'), (r) => r);

/// Unwraps the failure side of an [Either], failing the test with the value if
/// it turned out to be a `Right`.
Failure leftOf<T>(Either<Failure, T> either) =>
    either.fold((l) => l, (r) => fail('expected a failure, got $r'));
