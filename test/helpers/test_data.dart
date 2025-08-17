import 'dart:io';
import 'package:faker/faker.dart';

// A global faker instance for all tests to use
final faker = Faker.withGenerator(MersenneTwisterGenerator());

void setupFaker() {
  // Read the seed from the environment variable set by the CI script
  final seed = Platform.environment['FAKER_SEED'];
  if (seed != null && int.tryParse(seed) != null) {
    // If a seed is provided (e.g., in CI or for local debugging), use it.
    faker.seed(int.parse(seed));
  }
  // If no seed is provided, faker defaults to a random seed.
}
