import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkEvent', () {
    test('DeepLinkStarted supports value comparisons', () {
      expect(const DeepLinkStarted(), equals(const DeepLinkStarted()));
      expect(
        const DeepLinkStarted(args: ['1']),
        equals(const DeepLinkStarted(args: ['1'])),
      );
      expect(
        const DeepLinkStarted(args: ['1']),
        isNot(equals(const DeepLinkStarted(args: ['2']))),
      );
    });

    test('DeepLinkReceived supports value comparisons', () {
      final uri1 = Uri.parse('https://example.com/1');
      final uri2 = Uri.parse('https://example.com/1');
      final uri3 = Uri.parse('https://example.com/2');

      expect(DeepLinkReceived(uri1), equals(DeepLinkReceived(uri2)));
      expect(DeepLinkReceived(uri1), isNot(equals(DeepLinkReceived(uri3))));
    });

    test('DeepLinkManualEntry supports value comparisons', () {
      expect(
        const DeepLinkManualEntry('1'),
        equals(const DeepLinkManualEntry('1')),
      );
      expect(
        const DeepLinkManualEntry('1'),
        isNot(equals(const DeepLinkManualEntry('2'))),
      );
    });
  });
}
