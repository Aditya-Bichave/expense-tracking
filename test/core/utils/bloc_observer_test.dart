import 'package:bloc/bloc.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBloc extends Mock implements Bloc<Object, Object> {}
class MockTransition extends Mock implements Transition<Object, Object> {}
class MockChange extends Mock implements Change<Object> {}

// Expose protected methods for testing
class TestableBlocObserver extends SimpleBlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
  }
}

void main() {
  test('SimpleBlocObserver handles lifecycle events without error', () {
    final observer = TestableBlocObserver();
    final bloc = MockBloc();

    // Test onChange
    final change = MockChange();
    observer.onChange(bloc, change);

    // Test onTransition
    final transition = MockTransition();
    observer.onTransition(bloc, transition);

    // Test onError
    try {
      observer.onError(bloc, Exception('test'), StackTrace.empty);
    } catch (e) {
      // Expected
    }

    // Test onClose
    observer.onClose(bloc);

    // Test onCreate
    observer.onCreate(bloc);
  });
}
