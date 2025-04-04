import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';

class AccountsTabPage extends StatelessWidget {
  const AccountsTabPage({super.key});

  // Removed _navigateToEditAccount as it's not needed directly here anymore
  // void _navigateToEditAccount(BuildContext context, AssetAccount account) { ... }

  void _navigateToAccountDetail(BuildContext context, AssetAccount account) {
    log.info(
        "[AccountsTabPage] Navigating to Account Detail Placeholder for ID: ${account.id}");
    // Navigate to Edit screen when tapping the card for now
    // Use pushNamed for routes potentially outside the shell branch
    context.pushNamed(RouteNames.editAccount,
        pathParameters: {RouteNames.paramAccountId: account.id},
        extra: account);

    // Original Detail Navigation (Uncomment if detail screen is implemented)
    // context.pushNamed(RouteNames.accountDetail,
    //     pathParameters: {RouteNames.paramAccountId: account.id});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    // Assuming AccountListBloc is provided globally
    return _buildContent(context, theme, modeTheme);
  }

  Widget _buildContent(
      BuildContext context, ThemeData theme, AppModeTheme? modeTheme) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<AccountListBloc>()
              .add(const LoadAccounts(forceReload: true));
          await context.read<AccountListBloc>().stream.firstWhere(
              (state) => state is! AccountListLoading || !state.isReloading);
        },
        child: ListView(
          padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
              const EdgeInsets.only(top: 8.0, bottom: 80.0),
          children: [
            // --- Assets Section ---
            const SectionHeader(title: 'Assets'),
            BlocBuilder<AccountListBloc, AccountListState>(
              builder: (context, state) {
                if (state is AccountListLoading && !state.isReloading) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator()));
                }
                if (state is AccountListError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                        child: Text('Error loading accounts: ${state.message}',
                            style: TextStyle(color: theme.colorScheme.error))),
                  );
                }
                if (state is AccountListLoaded ||
                    (state is AccountListLoading && state.isReloading)) {
                  // Ensure we cast correctly to access items
                  final accounts = (state is AccountListLoaded)
                      ? state.items
                      : (context.read<AccountListBloc>().state
                              is AccountListLoaded)
                          ? (context.read<AccountListBloc>().state
                                  as AccountListLoaded)
                              .items
                          : <AssetAccount>[]; // Default to empty list

                  final double totalAssets = accounts.fold(
                      0.0, (sum, acc) => sum + acc.currentBalance);
                  final settingsState = context.watch<SettingsBloc>().state;
                  final currencySymbol = settingsState.currencySymbol;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Assets:',
                                style: theme.textTheme.titleMedium),
                            Text(
                              CurrencyFormatter.format(
                                  totalAssets, currencySymbol),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No asset accounts added yet.\nTap the "+" button to add one.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center, // Center align text
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: accounts.length,
                          itemBuilder: (ctx, index) {
                            final account = accounts[index];
                            return AccountCard(
                              account: account,
                              onTap: () => _navigateToAccountDetail(
                                  context, account), // Navigate on tap
                            );
                          },
                        ),
                      // --- REMOVED Add Asset Account Button ---
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      //   child: OutlinedButton.icon(...)
                      // ),
                      // --- END REMOVED ---
                    ],
                  );
                }
                // Fallback for Initial state
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator()));
              },
            ),

            const Divider(height: 30),

            // --- Liabilities Section (Remains the same) ---
            const SectionHeader(title: 'Liabilities'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Liabilities:',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.disabledColor)),
                  Text(
                    'TBD', // Placeholder value
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                  child: Text(
                'Liability accounts (Credit Cards, Loans) coming soon!',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              )),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: OutlinedButton.icon(
                icon:
                    Icon(Icons.add_circle_outline, color: theme.disabledColor),
                label: Text('Add Liability Account',
                    style: TextStyle(color: theme.disabledColor)),
                onPressed: null, // Disabled for now
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: theme.textTheme.labelLarge,
                  side: BorderSide(color: theme.disabledColor.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
