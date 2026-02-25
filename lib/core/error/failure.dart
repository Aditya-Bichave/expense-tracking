import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = "A server error occurred."]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = "A local data storage error occurred."]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = "Please check your network connection.",
  ]);
}

class SettingsFailure extends Failure {
  const SettingsFailure(super.message);
}

class BackupFailure extends Failure {
  const BackupFailure(super.message);
}

class RestoreFailure extends Failure {
  const RestoreFailure(super.message);
}

class ClearDataFailure extends Failure {
  const ClearDataFailure(super.message);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = "An unexpected error occurred."]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
