import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkState', () {
    test('DeepLinkInitial supports value comparisons', () {
      expect(DeepLinkInitial(), equals(DeepLinkInitial()));
    });

    test('DeepLinkProcessing supports value comparisons', () {
      expect(DeepLinkProcessing(), equals(DeepLinkProcessing()));
    });

    test('DeepLinkSuccess supports value comparisons', () {
      expect(
        const DeepLinkSuccess(groupId: '1', groupName: 'Group 1'),
        equals(const DeepLinkSuccess(groupId: '1', groupName: 'Group 1')),
      );
      expect(
        const DeepLinkSuccess(groupId: '1', groupName: 'Group 1'),
        isNot(
          equals(const DeepLinkSuccess(groupId: '2', groupName: 'Group 1')),
        ),
      );
    });

    test('DeepLinkError supports value comparisons', () {
      expect(
        const DeepLinkError('error'),
        equals(const DeepLinkError('error')),
      );
      expect(
        const DeepLinkError('error1'),
        isNot(equals(const DeepLinkError('error2'))),
      );
    });
  });
}
