import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('AppLocalizations returns correct strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(AppLocalizations.of(context)!.incomeVsExpense),
              Text(AppLocalizations.of(context)!.accounts),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Income vs Expense'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(AppLocalizations.of(context)!.incomeVsExpense),
              Text(AppLocalizations.of(context)!.accounts),
            ],
          ),
        ),
      ),
    );
    expect(find.text('الدخل مقابل المصروفات'), findsOneWidget);
    expect(find.text('الحسابات'), findsOneWidget);
  });
}
