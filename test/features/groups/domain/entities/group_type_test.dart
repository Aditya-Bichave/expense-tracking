import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupType', () {
    test('fromValue should return correct enum', () {
      expect(GroupType.fromValue('trip'), GroupType.trip);
      expect(GroupType.fromValue('couple'), GroupType.couple);
      expect(GroupType.fromValue('home'), GroupType.home);
      expect(GroupType.fromValue('custom'), GroupType.custom);
    });

    test('fromValue should return custom for unknown values', () {
      expect(GroupType.fromValue('unknown'), GroupType.custom);
      expect(GroupType.fromValue(''), GroupType.custom);
    });

    test('fromValue should be case sensitive', () {
      expect(GroupType.fromValue('Trip'), GroupType.custom);
      expect(GroupType.fromValue('COUPLE'), GroupType.custom);
    });

    test('value getter should return correct string', () {
      expect(GroupType.trip.value, 'trip');
      expect(GroupType.couple.value, 'couple');
      expect(GroupType.home.value, 'home');
      expect(GroupType.custom.value, 'custom');
    });
  });
}
