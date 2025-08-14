import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failure.dart';

// Use dartz for Functional Error Handling (Either<Failure, Success>)

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

// Parameter class if no parameters are needed
class NoParams extends Equatable {
  const NoParams(); // Added const constructor

  @override
  List<Object?> get props => [];
}
