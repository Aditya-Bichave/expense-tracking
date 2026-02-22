import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';

class LoginWithMagicLinkUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  LoginWithMagicLinkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await repository.signInWithMagicLink(email);
  }
}
