import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_suggestion.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';

void main() {
  const tCategory = Category.uncategorized;
  const tConfidence = 0.85;

  group('CategorizationSuggestion', () {
    test('props should contain suggestedCategory and confidenceScore', () {
      const suggestion = CategorizationSuggestion(
        suggestedCategory: tCategory,
        confidenceScore: tConfidence,
      );
      expect(suggestion.props, [tCategory, tConfidence]);
    });

    test('supports value equality', () {
      const suggestion1 = CategorizationSuggestion(
        suggestedCategory: tCategory,
        confidenceScore: tConfidence,
      );
      const suggestion2 = CategorizationSuggestion(
        suggestedCategory: tCategory,
        confidenceScore: tConfidence,
      );
      expect(suggestion1, equals(suggestion2));
    });
  });
}
