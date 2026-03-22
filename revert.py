import os

def revert_optimization():
    path = "lib/features/reports/data/repositories/report_repository_impl.dart"
    with open(path, 'r') as f:
        content = f.read()

    old_str = """      // ⚡ Bolt Performance Optimization
      // Problem: `?? fallbackDate` inside .sort() adds constant overhead inside O(N log N) loops
      // Solution: Precompute sort keys or fallback values
      // Impact: Reduces object creation overhead during array sort for large goal sets
      final fallbackDate = DateTime(2100);
      final sortKeys = {
        for (var p in progressList)
          p.goal.id: p.goal.targetDate ?? fallbackDate,
      };
      progressList.sort(
        (a, b) => sortKeys[a.goal.id]!.compareTo(sortKeys[b.goal.id]!),
      );"""

    new_str = """      final fallbackDate = DateTime(2100);
      progressList.sort(
        (a, b) => (a.goal.targetDate ?? fallbackDate).compareTo(
          b.goal.targetDate ?? fallbackDate,
        ),
      );"""

    if old_str in content:
        content = content.replace(old_str, new_str)
        with open(path, 'w') as f:
            f.write(content)
        print("Reverted sorting optimization in report_repository_impl.dart to restore coverage")
    else:
        print("Optimization block not found")

revert_optimization()
