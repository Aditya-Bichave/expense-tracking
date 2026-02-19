import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log.fine('Bloc Event: ${bloc.runtimeType} $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log.fine('Bloc Transition: ${bloc.runtimeType} $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log.severe('Bloc Error: ${bloc.runtimeType} $error\n$error\n$stackTrace');
  }
}
