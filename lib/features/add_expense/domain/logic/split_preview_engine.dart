import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';

class SplitPreviewEngine {
  /// Distributes totalAmount equally among members, handling penny remainders.
  static List<SplitModel> calculateEqualSplits(
    double totalAmount,
    List<GroupMember> members,
  ) {
    if (members.isEmpty) return [];

    // Working with cents to avoid floating point issues during division
    int totalCents = (totalAmount * 100).round();
    int count = members.length;
    if (count == 0) return [];

    int baseShareCents = totalCents ~/ count;
    int remainderCents = totalCents % count;

    List<SplitModel> results = [];
    for (int i = 0; i < count; i++) {
      // Distribute remainder cents to the first 'remainderCents' members
      int currentShareCents = baseShareCents + (i < remainderCents ? 1 : 0);
      double computed = currentShareCents / 100.0;

      results.add(
        SplitModel(
          userId: members[i].userId,
          shareType: SplitType.EQUAL,
          shareValue: 1.0, // Represents 1 equal part
          computedAmount: computed,
        ),
      );
    }
    return results;
  }

  /// Recalculates amounts based on percentages.
  /// Does NOT validate sum=100 here, just computes amounts.
  static List<SplitModel> calculatePercentSplits(
    double totalAmount,
    List<SplitModel> currentSplits,
  ) {
    return currentSplits.map((split) {
      if (split.shareType != SplitType.PERCENT) return split;
      double computed = (totalAmount * split.shareValue) / 100.0;
      // Round to 2 decimals
      computed = (computed * 100).roundToDouble() / 100.0;
      return split.copyWith(computedAmount: computed);
    }).toList();
  }

  /// Recalculates amounts based on shares (weighted average).
  static List<SplitModel> calculateShareSplits(
    double totalAmount,
    List<SplitModel> currentSplits,
  ) {
    double totalShares = currentSplits.fold(
      0,
      (sum, split) => sum + split.shareValue,
    );

    if (totalShares == 0) {
      return currentSplits.map((s) => s.copyWith(computedAmount: 0)).toList();
    }

    int totalCents = (totalAmount * 100).round();

    // First pass: calculate raw shares
    List<int> computedCents = [];
    int distributedCents = 0;

    for (var split in currentSplits) {
      double ratio = split.shareValue / totalShares;
      int shareCents = (totalCents * ratio)
          .floor(); // Floor to ensure we don't over-allocate initially
      computedCents.add(shareCents);
      distributedCents += shareCents;
    }

    // Distribute remainder
    int remainder = totalCents - distributedCents;

    // Naive distribution of remainder to first items with shares > 0
    for (int i = 0; i < computedCents.length && remainder > 0; i++) {
      if (currentSplits[i].shareValue > 0) {
        computedCents[i]++;
        remainder--;
      }
    }

    // Convert back to models
    List<SplitModel> results = [];
    for (int i = 0; i < currentSplits.length; i++) {
      results.add(
        currentSplits[i].copyWith(computedAmount: computedCents[i] / 100.0),
      );
    }

    return results;
  }

  static bool validatePercent(List<SplitModel> splits) {
    double sum = splits.fold(0.0, (prev, e) => prev + e.shareValue);
    return (sum - 100.0).abs() < 0.01;
  }

  static bool validateExact(List<SplitModel> splits, double totalAmount) {
    double sum = splits.fold(0.0, (prev, e) => prev + e.computedAmount);
    return (sum - totalAmount).abs() < 0.01;
  }
}
