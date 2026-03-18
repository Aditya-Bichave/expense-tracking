import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:expense_tracker/core/di/service_locator.dart';

class TestService {
  final int value;
  TestService(this.value);
}

void main() {
  setUp(() async {
    await sl.reset();
  });

  test('registers and resolves singleton', () {
    sl.registerSingleton<TestService>(TestService(1));
    final instance1 = sl.get<TestService>();
    final instance2 = sl.get<TestService>();

    expect(instance1.value, 1);
    expect(identical(instance1, instance2), isTrue);
  });

  test('factory returns new instances', () {
    int counter = 0;
    sl.registerFactory<TestService>(() => TestService(++counter));

    final instance1 = sl.get<TestService>();
    final instance2 = sl.get<TestService>();

    expect(instance1.value, 1);
    expect(instance2.value, 2);
    expect(identical(instance1, instance2), isFalse);
  });

  test('reset clears registrations', () async {
    sl.registerSingleton<TestService>(TestService(1));
    final instance1 = sl.get<TestService>();
    expect(instance1, isNotNull);

    await sl.reset();

    expect(() => sl.get<TestService>(), throwsStateError);
  });
}
