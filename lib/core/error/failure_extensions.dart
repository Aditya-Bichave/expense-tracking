import 'failure.dart';

extension FailureMessage on Failure {
  String toDisplayMessage({String? context}) {
    String specificMessage;
    switch (this) {
      case CacheFailure _:
      case SettingsFailure _:
        specificMessage = 'Database Error: $message';
        break;
      case ValidationFailure _:
        specificMessage = message;
        break;
      case UnexpectedFailure _:
        specificMessage = 'An unexpected error occurred. Please try again.';
        break;
      default:
        specificMessage = message.isNotEmpty
            ? message
            : 'An unknown error occurred.';
    }
    if (context != null && context.isNotEmpty) {
      return '$context: $specificMessage';
    }
    return specificMessage;
  }
}
