// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get incomeVsExpense => 'Income vs Expense';

  @override
  String get comparePeriod => 'Compare Period';

  @override
  String get hideComparison => 'Hide Comparison';

  @override
  String get changePeriodAggregation => 'Change Period Aggregation';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockSubtitle => 'Require authentication on launch/resume';

  @override
  String get changePassword => 'Change Password';

  @override
  String get disabledInDemoMode => 'Disabled in Demo Mode';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get frequency => 'Frequency';

  @override
  String get selectTime => 'Select Time';

  @override
  String get dayOfWeek => 'Day of Week';

  @override
  String get addRecurringRule => 'Add Recurring Rule';

  @override
  String get editRecurringRule => 'Edit Recurring Rule';

  @override
  String get anErrorOccurred => 'An error occurred.';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get showPieChart => 'Show Pie Chart';

  @override
  String get showBarChart => 'Show Bar Chart';

  @override
  String get budgetPerformance => 'Budget Performance';

  @override
  String get compareToPreviousPeriod => 'Compare to Previous Period';

  @override
  String get noBudgetsFoundForPeriod => 'No budgets found for this period.';

  @override
  String get spendingOverTime => 'Spending Over Time';

  @override
  String get changeGranularity => 'Change Granularity';

  @override
  String get reportDataNotLoadedYet => 'Report data not loaded yet.';

  @override
  String get dayOfMonth => 'Day of Month';

  @override
  String get ends => 'Ends';

  @override
  String get selectEndDate => 'Select End Date';

  @override
  String get numberOfOccurrences => 'Number of Occurrences';

  @override
  String get save => 'Save';

  @override
  String get contributionDate => 'Contribution Date';

  @override
  String get accounts => 'Accounts';

  @override
  String get noAccountsYet => 'No accounts yet!';

  @override
  String get addAccountEmptyDescription =>
      'Tap the \"+\" button below to add your first bank account, cash wallet, or other assets.';

  @override
  String get addFirstAccount => 'Add First Account';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String deleteAccountConfirmation(Object accountName) {
    return 'Are you sure you want to delete the account \"$accountName\"?\\n\\nThis action might fail if there are existing transactions linked to this account.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get errorLoadingAccounts => 'Error loading accounts';

  @override
  String get retry => 'Retry';

  @override
  String get addAccount => 'Add Account';
}
