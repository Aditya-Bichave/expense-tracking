import 'dart:io';
import 'dart:math';
import 'package:faker/faker.dart';

/// Global faker instance for generating deterministic test data when a seed is
/// provided via the `FAKER_SEED` environment variable.
late Faker faker;

void setupFaker() {
  final seed = Platform.environment['FAKER_SEED'];
  if (seed != null && int.tryParse(seed) != null) {
    final parsed = int.parse(seed);
    faker = Faker.withGenerator(RandomGenerator(seed: parsed));
  } else {
    faker = Faker();
  }
}
