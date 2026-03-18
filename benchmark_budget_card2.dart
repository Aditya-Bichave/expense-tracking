import 'dart:core';

class Category {
  final String id;
  final String name;
  Category(this.id, this.name);
}

void main() {
  final expenseCategories = List.generate(500, (i) => Category('exp_$i', 'Expense $i'));
  final incomeCategories = List.generate(500, (i) => Category('inc_$i', 'Income $i'));

  // A large list of budget category ids, some present, some not,
  // making sure we loop through a decent amount to see the map's advantage.
  final budgetCategoryIds = List.generate(20, (i) => 'none_$i')
    ..addAll(['exp_490', 'exp_491', 'exp_492']);

  final Category uncategorized = Category('uncategorized', 'Uncategorized');

  // Baseline approach
  void runBaseline() {
    final allCategories = [
      ...expenseCategories,
      ...incomeCategories,
    ];
    int count = 0;
    for (String id in budgetCategoryIds) {
      if (count >= 3) break;

      // firstWhereOrNull logic
      Category? category;
      for (var c in allCategories) {
        if (c.id == id) {
          category = c;
          break;
        }
      }

      if (category != null && category.id != uncategorized.id) {
        count++;
      }
    }
  }

  // Optimized approach
  void runOptimized() {
    final allCategoriesMap = {
      for (var c in expenseCategories) c.id: c,
      for (var c in incomeCategories) c.id: c,
    };
    int count = 0;
    for (String id in budgetCategoryIds) {
      if (count >= 3) break;

      final category = allCategoriesMap[id];

      if (category != null && category.id != uncategorized.id) {
        count++;
      }
    }
  }

  // Warmup
  for (int i = 0; i < 1000; i++) {
    runBaseline();
    runOptimized();
  }

  final sw1 = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    runBaseline();
  }
  sw1.stop();

  final sw2 = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    runOptimized();
  }
  sw2.stop();

  print('Baseline time: ${sw1.elapsedMicroseconds} us');
  print('Optimized time: ${sw2.elapsedMicroseconds} us');
}
