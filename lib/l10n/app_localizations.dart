import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @incomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense'**
  String get incomeVsExpense;

  /// No description provided for @comparePeriod.
  ///
  /// In en, this message translates to:
  /// **'Compare Period'**
  String get comparePeriod;

  /// No description provided for @hideComparison.
  ///
  /// In en, this message translates to:
  /// **'Hide Comparison'**
  String get hideComparison;

  /// No description provided for @changePeriodAggregation.
  ///
  /// In en, this message translates to:
  /// **'Change Period Aggregation'**
  String get changePeriodAggregation;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require authentication on launch/resume'**
  String get appLockSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @disabledInDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Disabled in Demo Mode'**
  String get disabledInDemoMode;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get featureComingSoon;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @dayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get dayOfWeek;

  /// No description provided for @addRecurringRule.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring Rule'**
  String get addRecurringRule;

  /// No description provided for @editRecurringRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring Rule'**
  String get editRecurringRule;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get anErrorOccurred;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @showPieChart.
  ///
  /// In en, this message translates to:
  /// **'Show Pie Chart'**
  String get showPieChart;

  /// No description provided for @showBarChart.
  ///
  /// In en, this message translates to:
  /// **'Show Bar Chart'**
  String get showBarChart;

  /// No description provided for @budgetPerformance.
  ///
  /// In en, this message translates to:
  /// **'Budget Performance'**
  String get budgetPerformance;

  /// No description provided for @compareToPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Compare to Previous Period'**
  String get compareToPreviousPeriod;

  /// No description provided for @noBudgetsFoundForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No budgets found for this period.'**
  String get noBudgetsFoundForPeriod;

  /// No description provided for @spendingOverTime.
  ///
  /// In en, this message translates to:
  /// **'Spending Over Time'**
  String get spendingOverTime;

  /// No description provided for @changeGranularity.
  ///
  /// In en, this message translates to:
  /// **'Change Granularity'**
  String get changeGranularity;

  /// No description provided for @reportDataNotLoadedYet.
  ///
  /// In en, this message translates to:
  /// **'Report data not loaded yet.'**
  String get reportDataNotLoadedYet;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of Month'**
  String get dayOfMonth;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;

  /// No description provided for @numberOfOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Number of Occurrences'**
  String get numberOfOccurrences;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @contributionDate.
  ///
  /// In en, this message translates to:
  /// **'Contribution Date'**
  String get contributionDate;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet!'**
  String get noAccountsYet;

  /// No description provided for @addAccountEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button below to add your first bank account, cash wallet, or other assets.'**
  String get addAccountEmptyDescription;

  /// No description provided for @addFirstAccount.
  ///
  /// In en, this message translates to:
  /// **'Add First Account'**
  String get addFirstAccount;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the account \"{accountName}\"?\\n\\nThis action might fail if there are existing transactions linked to this account.'**
  String deleteAccountConfirmation(Object accountName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @errorLoadingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts'**
  String get errorLoadingAccounts;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get goalProgress;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
