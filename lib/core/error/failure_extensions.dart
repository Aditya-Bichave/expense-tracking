import 'failure.dart';

extension FailureMessage on Failure {
  String toDisplayMessage({String? context}) {
    String specificMessage;
    switch (runtimeType) {
      case CacheFailure:
      case SettingsFailure:
        specificMessage = 'Database Error: $message';
        break;
      case ValidationFailure:
        specificMessage = message;
        break;
      case UnexpectedFailure:
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
