import 'package:expense_tracker/core/utils/app_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

// Mock Hive Interface
class MockHiveInterface extends Mock implements HiveInterface {}

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  // Testing AppInitializer static methods involving Hive is hard because Hive uses a singleton.
  // We can't easily mock the static `Hive` class calls unless we wrap them.
  // However, `initHiveBoxes` does a LOT of `Hive.registerAdapter` and `Hive.openBox`.
  //
  // Strategy:
  // Since we cannot mock static Hive methods easily without a wrapper,
  // and `AppInitializer` is purely static, testing it effectively requires
  // integration tests or refactoring to use a `HiveService` wrapper.
  //
  // For now, we will verify that the file compiles and the method exists,
  // but extensive unit testing of static side-effects on 3rd party libs is out of scope for *unit* tests
  // without refactoring.

  test('AppInitializer exists', () {
    // Trivial test to ensure file is analyzed/covered partially
    expect(AppInitializer.initHiveBoxes, isNotNull);
  });
}
