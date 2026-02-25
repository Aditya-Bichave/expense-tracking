enum FormStatus { initial, processing, success, error }

enum SplitMode {
  equal,
  exact,
  percent,
  shares;

  String get displayName {
    switch (this) {
      case SplitMode.equal:
        return 'Equal Split';
      case SplitMode.exact:
        return 'Exact Amounts';
      case SplitMode.percent:
        return 'Percentages';
      case SplitMode.shares:
        return 'Shares';
    }
  }
}
