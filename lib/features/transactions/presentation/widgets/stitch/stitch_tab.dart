enum StitchTab {
  personal,
  group,
  income,
  settlement;

  String get label {
    switch (this) {
      case StitchTab.personal:
        return 'Personal';
      case StitchTab.group:
        return 'Group';
      case StitchTab.income:
        return 'Income';
      case StitchTab.settlement:
        return 'Settlement';
    }
  }
}
