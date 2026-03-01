import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';

void main() {
  group('GroupType', () {
    test('enum values map correctly', () {
      expect(GroupType.trip.value, 'trip');
      expect(GroupType.couple.value, 'couple');
      expect(GroupType.home.value, 'home');
      expect(GroupType.custom.value, 'custom');
    });

    test('fromValue parses valid strings', () {
      expect(GroupType.fromValue('trip'), GroupType.trip);
      expect(GroupType.fromValue('couple'), GroupType.couple);
      expect(GroupType.fromValue('home'), GroupType.home);
      expect(GroupType.fromValue('custom'), GroupType.custom);
    });

    test('fromValue defaults to custom on invalid string', () {
      expect(GroupType.fromValue('unknown'), GroupType.custom);
      expect(GroupType.fromValue(''), GroupType.custom);
    });
  });
}
