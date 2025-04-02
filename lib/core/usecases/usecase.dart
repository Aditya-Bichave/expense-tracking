import 'package:dartz/dartz.dart'; // Add dartz: ^0.10.1 to pubspec.yaml
import 'package:equatable/equatable.dart';
import '../error/failure.dart';

// Use dartz for Functional Error Handling (Either<Failure, Success>)
// Add dependency: dartz: ^0.10.1

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Parameter class if no parameters are needed
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
