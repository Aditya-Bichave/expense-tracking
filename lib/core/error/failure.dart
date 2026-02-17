import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([String message = "A server error occurred."])
    : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = "A local data storage error occurred."])
    : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    String message = "Please check your network connection.",
  ]) : super(message);
}

class SettingsFailure extends Failure {
  const SettingsFailure(String message) : super(message);
}

class BackupFailure extends Failure {
  const BackupFailure(String message) : super(message);
}

class RestoreFailure extends Failure {
  const RestoreFailure(String message) : super(message);
}

class ClearDataFailure extends Failure {
  const ClearDataFailure(String message) : super(message);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(String message) : super(message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = "An unexpected error occurred."])
    : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}
