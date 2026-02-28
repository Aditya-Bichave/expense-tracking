import 'package:bloc/bloc.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock Bloc
class MockBloc extends Bloc<int, int> {
  MockBloc() : super(0) {
    on<int>((event, emit) => emit(event));
  }
}

void main() {
  group('SimpleBlocObserver', () {
    late SimpleBlocObserver observer;

    setUp(() {
      observer = SimpleBlocObserver();
    });

    test('handles lifecycle events without error', () {
      final bloc = MockBloc();

      // We can't verify log output easily without mocking Logger,
      // but we can ensure methods don't crash.
      observer.onEvent(bloc, 1);
      observer.onTransition(
        bloc,
        const Transition(currentState: 0, event: 1, nextState: 1),
      );

      // We expect onError to log but not crash.
      // We wrap in runZonedGuarded or just verify returnsNormally.
      // NOTE: In some test runners, unhandled async errors or severe logs trigger failures.
      // Since SimpleBlocObserver catches nothing and just logs, if the exception passed is real,
      // it might be flagged.
      // Here we simply check that the observer method itself doesn't throw *another* exception.
      expect(
        () => observer.onError(bloc, Exception('test error'), StackTrace.empty),
        returnsNormally,
      );
    });
  });
}
