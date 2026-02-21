import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';

void main() {
  group('CategorizationStatus', () {
    test('values should return correct string representations', () {
      expect(CategorizationStatus.uncategorized.value, 'uncategorized');
      expect(CategorizationStatus.needsReview.value, 'needs_review');
      expect(CategorizationStatus.categorized.value, 'categorized');
    });

    test('fromValue should return correct enum from string', () {
      expect(
        CategorizationStatusExtension.fromValue('uncategorized'),
        CategorizationStatus.uncategorized,
      );
      expect(
        CategorizationStatusExtension.fromValue('needs_review'),
        CategorizationStatus.needsReview,
      );
      expect(
        CategorizationStatusExtension.fromValue('categorized'),
        CategorizationStatus.categorized,
      );
    });

    test('fromValue should return uncategorized for unknown strings', () {
      expect(
        CategorizationStatusExtension.fromValue('unknown_value'),
        CategorizationStatus.uncategorized,
      );
      expect(
        CategorizationStatusExtension.fromValue(null),
        CategorizationStatus.uncategorized,
      );
    });
  });
}
