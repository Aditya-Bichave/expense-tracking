import 'package:bloc/bloc.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_logger/simple_logger.dart';

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
      // Silence logger to prevent SEVERE logs from failing CI if strict
      log.setLevel(Level.OFF, includeCallerInfo: false);
    });

    tearDown(() {
      log.setLevel(Level.INFO, includeCallerInfo: false);
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
      expect(
        () => observer.onError(bloc, Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
